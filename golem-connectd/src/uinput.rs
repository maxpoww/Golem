// A virtual Xbox-360-compatible gamepad on /dev/uinput.
//
// Why uinput here when the pointer and keyboard go through Wayland: there is
// no virtual-gamepad Wayland protocol, and there cannot usefully be one —
// games read /dev/input directly through SDL/evdev, not through the
// compositor. So this is the one input path that needs a kernel device.
//
// It therefore needs write access to /dev/uinput, which is NOT granted by
// default. On NixOS:
//
//     hardware.uinput.enable = true;              # udev rule + `uinput` group
//     users.users.<you>.extraGroups = [ "uinput" ];
//
// The device is created LAZILY, on the first event, and destroyed on
// disconnect. A virtual pad created at startup would sit in every game's
// controller list for as long as the daemon runs, whether or not a phone is
// anywhere nearby.
//
// The ioctl numbers are computed from the struct sizes rather than written as
// magic constants, so a layout mistake cannot silently produce a wrong request
// number that the kernel rejects with a bare EINVAL.

use anyhow::{bail, Context, Result};
use std::ffi::CString;
use std::sync::mpsc::{self, Receiver, Sender};

use crate::gamepad::{
    GamepadEvent, ABS_HAT0X, ABS_HAT0Y, ABS_RZ, ABS_Z, ALL_AXES, ALL_BUTTONS, EV_ABS, EV_KEY,
    EV_SYN, STICK_MAX, SYN_REPORT, TRIGGER_MAX,
};

const UINPUT_MAX_NAME_SIZE: usize = 80;
const BUS_VIRTUAL: u16 = 0x06;

// The phone presents as a wired Xbox 360 pad: SDL, Steam and Proton all
// recognise that VID/PID pair without any user-supplied mapping.
const VENDOR_MICROSOFT: u16 = 0x045e;
const PRODUCT_XBOX360_PAD: u16 = 0x028e;
const DEVICE_NAME: &str = "Golem Gamepad";

#[repr(C)]
#[derive(Default)]
struct InputId {
    bustype: u16,
    vendor: u16,
    product: u16,
    version: u16,
}

#[repr(C)]
struct UinputSetup {
    id: InputId,
    name: [u8; UINPUT_MAX_NAME_SIZE],
    ff_effects_max: u32,
}

#[repr(C)]
#[derive(Default)]
struct InputAbsinfo {
    value: i32,
    minimum: i32,
    maximum: i32,
    fuzz: i32,
    flat: i32,
    resolution: i32,
}

#[repr(C)]
struct UinputAbsSetup {
    code: u16,
    absinfo: InputAbsinfo,
}

#[repr(C)]
struct RawInputEvent {
    time: libc::timeval,
    kind: u16,
    code: u16,
    value: i32,
}

// _IO / _IOW from linux/ioctl.h, with UINPUT_IOCTL_BASE == 'U'.
const IOC_WRITE: libc::c_ulong = 1;
const UINPUT_BASE: libc::c_ulong = b'U' as libc::c_ulong;

const fn io(nr: libc::c_ulong) -> libc::c_ulong {
    (UINPUT_BASE << 8) | nr
}

const fn iow(nr: libc::c_ulong, size: usize) -> libc::c_ulong {
    (IOC_WRITE << 30) | ((size as libc::c_ulong) << 16) | (UINPUT_BASE << 8) | nr
}

fn ui_dev_create() -> libc::c_ulong {
    io(1)
}
fn ui_dev_destroy() -> libc::c_ulong {
    io(2)
}
fn ui_dev_setup() -> libc::c_ulong {
    iow(3, std::mem::size_of::<UinputSetup>())
}
fn ui_abs_setup() -> libc::c_ulong {
    iow(4, std::mem::size_of::<UinputAbsSetup>())
}
fn ui_set_evbit() -> libc::c_ulong {
    iow(100, std::mem::size_of::<libc::c_int>())
}
fn ui_set_keybit() -> libc::c_ulong {
    iow(101, std::mem::size_of::<libc::c_int>())
}
fn ui_set_absbit() -> libc::c_ulong {
    iow(103, std::mem::size_of::<libc::c_int>())
}

fn open_uinput() -> Result<libc::c_int> {
    let path = CString::new("/dev/uinput").unwrap();
    let fd = unsafe { libc::open(path.as_ptr(), libc::O_WRONLY | libc::O_NONBLOCK) };
    if fd < 0 {
        let err = std::io::Error::last_os_error();
        if err.kind() == std::io::ErrorKind::PermissionDenied {
            bail!(
                "/dev/uinput is not writable ({err}). On NixOS add \
                 `hardware.uinput.enable = true;` and put your user in the \
                 `uinput` group, then log out and back in."
            );
        }
        bail!("opening /dev/uinput: {err}");
    }
    Ok(fd)
}

/// Can we create a gamepad at all? Opens and immediately closes, so it answers
/// the permission question without leaving a phantom controller behind.
/// Capabilities are advertised on the strength of this, so a phone never sees
/// a gamepad button that could not possibly work.
pub fn probe() -> Result<()> {
    let fd = open_uinput()?;
    unsafe { libc::close(fd) };
    Ok(())
}

struct Device {
    fd: libc::c_int,
}

impl Device {
    fn create() -> Result<Self> {
        let fd = open_uinput()?;
        let device = Device { fd };
        device.declare_capabilities().context("declaring gamepad capabilities")?;
        device.setup().context("UI_DEV_SETUP")?;
        device.configure_axes().context("UI_ABS_SETUP")?;
        device.ioctl(ui_dev_create(), 0).context("UI_DEV_CREATE")?;
        Ok(device)
    }

    fn ioctl(&self, request: libc::c_ulong, arg: libc::c_ulong) -> Result<()> {
        let rc = unsafe { libc::ioctl(self.fd, request, arg) };
        if rc < 0 {
            bail!("{}", std::io::Error::last_os_error());
        }
        Ok(())
    }

    fn ioctl_ptr<T>(&self, request: libc::c_ulong, value: &T) -> Result<()> {
        let rc = unsafe { libc::ioctl(self.fd, request, value as *const T) };
        if rc < 0 {
            bail!("{}", std::io::Error::last_os_error());
        }
        Ok(())
    }

    /// Every code the wire can name must be declared here; the kernel silently
    /// drops writes for codes a device never claimed.
    fn declare_capabilities(&self) -> Result<()> {
        self.ioctl(ui_set_evbit(), EV_KEY as libc::c_ulong)?;
        self.ioctl(ui_set_evbit(), EV_ABS as libc::c_ulong)?;
        self.ioctl(ui_set_evbit(), EV_SYN as libc::c_ulong)?;
        for code in ALL_BUTTONS {
            self.ioctl(ui_set_keybit(), code as libc::c_ulong)?;
        }
        for code in ALL_AXES {
            self.ioctl(ui_set_absbit(), code as libc::c_ulong)?;
        }
        Ok(())
    }

    fn setup(&self) -> Result<()> {
        let mut name = [0u8; UINPUT_MAX_NAME_SIZE];
        let bytes = DEVICE_NAME.as_bytes();
        name[..bytes.len()].copy_from_slice(bytes);
        let setup = UinputSetup {
            id: InputId {
                bustype: BUS_VIRTUAL,
                vendor: VENDOR_MICROSOFT,
                product: PRODUCT_XBOX360_PAD,
                version: 0x0114,
            },
            name,
            ff_effects_max: 0,
        };
        self.ioctl_ptr(ui_dev_setup(), &setup)
    }

    fn configure_axes(&self) -> Result<()> {
        for code in ALL_AXES {
            // Triggers are unsigned bytes, the hat is a three-position switch,
            // and the sticks are full-range signed — three different shapes on
            // one device.
            let (minimum, maximum, flat) = match code {
                ABS_Z | ABS_RZ => (0, TRIGGER_MAX, 0),
                ABS_HAT0X | ABS_HAT0Y => (-1, 1, 0),
                // `flat` is the driver-side dead zone. An on-screen stick
                // returns to exact zero on release, so asking the kernel for a
                // dead zone as well would only eat real travel.
                _ => (-STICK_MAX, STICK_MAX, 0),
            };
            let abs = UinputAbsSetup {
                code,
                absinfo: InputAbsinfo { minimum, maximum, flat, ..Default::default() },
            };
            self.ioctl_ptr(ui_abs_setup(), &abs)?;
        }
        Ok(())
    }

    fn write_event(&self, kind: u16, code: u16, value: i32) -> Result<()> {
        // A zero timestamp tells the kernel to stamp it on arrival.
        let event = RawInputEvent {
            time: libc::timeval { tv_sec: 0, tv_usec: 0 },
            kind,
            code,
            value,
        };
        let size = std::mem::size_of::<RawInputEvent>();
        let written = unsafe {
            libc::write(self.fd, &event as *const RawInputEvent as *const libc::c_void, size)
        };
        if written != size as isize {
            bail!("short write to /dev/uinput: {}", std::io::Error::last_os_error());
        }
        Ok(())
    }

    /// One SYN_REPORT per packet, not per event: a diagonal stick move must
    /// reach the game as a single frame, or it reads as two axis steps.
    fn sync(&self) -> Result<()> {
        self.write_event(EV_SYN, SYN_REPORT, 0)
    }

    fn release_all(&self) -> Result<()> {
        for code in ALL_BUTTONS {
            self.write_event(EV_KEY, code, 0)?;
        }
        for code in ALL_AXES {
            self.write_event(EV_ABS, code, 0)?;
        }
        self.sync()
    }
}

impl Drop for Device {
    fn drop(&mut self) {
        // Best effort: releasing first means a game does not see the last held
        // button as still down at the moment the device vanishes.
        let _ = self.release_all();
        let _ = self.ioctl(ui_dev_destroy(), 0);
        unsafe { libc::close(self.fd) };
    }
}

/// Start the gamepad sink. Each `Vec<GamepadEvent>` is one packet's worth of
/// changes and becomes one input frame.
pub fn spawn_gamepad_sink() -> Sender<Vec<GamepadEvent>> {
    let (tx, rx) = mpsc::channel::<Vec<GamepadEvent>>();
    std::thread::spawn(move || run_sink(rx));
    tx
}

fn run_sink(rx: Receiver<Vec<GamepadEvent>>) {
    let mut device: Option<Device> = None;

    for frame in rx {
        if frame.is_empty() {
            continue;
        }

        if frame.iter().any(|e| matches!(e, GamepadEvent::Disconnect)) {
            if device.take().is_some() {
                println!("gamepad: virtual controller removed");
            }
            continue;
        }

        // Lazily created, so an idle Golem leaves no phantom pad behind.
        if device.is_none() {
            match Device::create() {
                Ok(created) => {
                    println!("gamepad: virtual controller created ({DEVICE_NAME})");
                    device = Some(created);
                }
                Err(e) => {
                    eprintln!("gamepad: cannot create virtual controller: {e:#}");
                    continue;
                }
            }
        }
        let Some(dev) = device.as_ref() else { continue };

        let result = apply(dev, &frame);
        if let Err(e) = result {
            eprintln!("gamepad: write failed, dropping the device: {e:#}");
            device = None;
        }
    }
}

fn apply(device: &Device, frame: &[GamepadEvent]) -> Result<()> {
    for event in frame {
        match event {
            GamepadEvent::Button { code, pressed } => {
                device.write_event(EV_KEY, *code, i32::from(*pressed))?;
            }
            GamepadEvent::Axis { code, value } => {
                device.write_event(EV_ABS, *code, *value)?;
            }
            GamepadEvent::ReleaseAll => device.release_all()?,
            GamepadEvent::Disconnect => {}
        }
    }
    device.sync()
}

#[cfg(test)]
mod tests {
    use super::*;

    // These pin the ABI. Getting a struct size wrong changes the ioctl request
    // number, and the kernel answers a wrong number with a bare EINVAL that
    // says nothing about which struct is malformed.

    #[test]
    fn structs_match_the_kernel_abi() {
        assert_eq!(std::mem::size_of::<InputId>(), 8);
        assert_eq!(std::mem::size_of::<UinputSetup>(), 92);
        assert_eq!(std::mem::size_of::<InputAbsinfo>(), 24);
        // 2 bytes of code, 2 of padding, then the absinfo.
        assert_eq!(std::mem::size_of::<UinputAbsSetup>(), 28);
    }

    #[test]
    fn ioctl_numbers_match_linux_uinput_h() {
        assert_eq!(ui_dev_create(), 0x5501);
        assert_eq!(ui_dev_destroy(), 0x5502);
        assert_eq!(ui_dev_setup(), 0x405c_5503);
        assert_eq!(ui_abs_setup(), 0x401c_5504);
        assert_eq!(ui_set_evbit(), 0x4004_5564);
        assert_eq!(ui_set_keybit(), 0x4004_5565);
        assert_eq!(ui_set_absbit(), 0x4004_5567);
    }

    #[test]
    fn input_event_is_the_native_evdev_record() {
        // 16-byte timeval on 64-bit, then type/code/value.
        assert_eq!(
            std::mem::size_of::<RawInputEvent>(),
            std::mem::size_of::<libc::timeval>() + 8
        );
    }

    #[test]
    fn device_name_fits_the_fixed_field() {
        assert!(DEVICE_NAME.len() < UINPUT_MAX_NAME_SIZE);
    }
}
