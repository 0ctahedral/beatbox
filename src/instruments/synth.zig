//! Synthesizer for making funky sounds!

const std = @import("std");
const Frame = @import("../frame.zig").Frame;
const envelope = @import("envelope.zig");
const notes = @import("notes.zig");
const osc = @import("oscillator.zig");
const Instrument = @import("instruments.zig").Instrument;

/// A synthesizer instrument
pub const Synth = struct {
    /// The volume of this synth
    volume: f32 = 1.0,
    /// Envelope that controls the way the amplitude of this synth
    env: envelope.ASDR,
    /// Oscilators that this synth uses to generate sound
    /// TODO: should this be a slice or array?
    oscilators: [3]osc.Oscillator,

    /// parent pointer to base instrument class
    parent: Instrument = .{
        .soundFn = sound,
    },

    /// Return the amplitude of this synth for the given note at the given time
    pub fn sound(inst: *Instrument, t: f64, n: *notes.Note) Frame {
        const self = @fieldParentPtr(Synth, "parent", inst);
        // build the sound
        // start with nothin
        var val: f64 = 0.0;

        // use all the oscillators that this synth has
        for (self.oscilators) |o| {
            val += o.val(t, notes.freqFromScale(.{.id=n.id, .octave=o.octave}));
        }

        // add envelope
        val *= self.env.getAmp(t, n) * self.volume;

        return .{
            .l = @floatCast(f32, val),
            .r = @floatCast(f32, val),
        };
    }
};

//--------------------------------------------------------------------------------
//                                   presets
//--------------------------------------------------------------------------------

pub fn Bell() Synth {
    return .{
        .env = .{
            .attack  = 0.01,
            .decay   = 1.0,
            .release = 1.0,
        },
        .oscilators = [_]osc.Oscillator{
            .{
                .osc_type = .sin,
                .lfo = .{.hertz=5.0, .amp =0.001}
            },
            .{
                .osc_type = .sin,
                .amplitude = 0.5,
                .octave = 2,
            },
            .{
                .osc_type = .sin,
                .amplitude = 0.25,
                .octave = 3,
            },
        },
    };
}
