const std = @import("std");
const math = std.math;
//TODO: make this a struct


var r = std.rand.DefaultPrng.init(12345);
/// Types of oscillators we can use
const OscType = enum {
    /// normal sin wave
    sin,
    /// square wave
    sqr,
    /// triangle wave
    tri,
    /// real saw wave
    asaw,
    /// digital saw wave
    dsaw,
    /// random noise
    noise,
};

/// angular velocity helper func
fn w(hertz: f64) f64 {
    return 2.0 * math.pi * hertz;
}

pub fn osc(hertz: f64 , dt: f64, oscType: OscType) f64 {
    return switch (oscType) {
        .sin => @sin(w(hertz) * dt),
        .sqr => {
            if (@sin(w(hertz) * dt) > 0) {
                return 1;
            } else {
                return 0;
            }
        },
        .tri => math.asin(@sin(w(hertz) * dt)) * 2.0 / math.pi,
        .dsaw => (2.0 / math.pi) * (hertz * math.pi * @mod(dt, 1.0/hertz) - (2.0 / math.pi)),
        // TODO: fix this
        .asaw => {
            var output: f64 = 0.0;
            var n: f64 = 0;
            while(n < 40) : (n+=1) {
                output += (@sin(n * w(hertz) * dt)) / n;
            }
            return output * (2.0 / math.pi);
        },
        .noise => r.random.float(f64),
    };
}
