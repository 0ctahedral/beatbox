// Use the newer ALSA API */
const std = @import("std");
const c = @cImport({
    @cInclude("alsa/asoundlib.h");
    @cDefine("ALSA_PCM_NEW_HW_PARAMS_API", "1");
});

pub fn main() anyerror!void {
    var loops: i64 = 0;
    var rc: i32 = 0;
    var size: u64 = 0;
    var handle: ?*c.snd_pcm_t = undefined;
    var params: ?*c.snd_pcm_hw_params_t = undefined;
    var val: u32 = undefined;
    var dir: i32 = 0;
    var frames: c.snd_pcm_uframes_t = 0;
//    var buffer: *u8 = undefined;

    // Open PCM device for playback. */
    rc = c.snd_pcm_open(&handle, "default",
        c._snd_pcm_stream.SND_PCM_STREAM_PLAYBACK, 0);
    if (rc < 0) {
        std.log.err("{c}", .{c.snd_strerror(rc)});
        return;
    }

    // Allocate a hardware parameters object. */
    _ = c.snd_pcm_hw_params_malloc(&params);

    // Fill it in with default values. */
    _ = c.snd_pcm_hw_params_any(handle, params);

    // Set the desired hardware parameters. */

    // Interleaved mode */
    _ = c.snd_pcm_hw_params_set_access(handle, params,
        c.snd_pcm_access_t.SND_PCM_ACCESS_RW_INTERLEAVED);

    // Signed 16-bit little-endian format */
    _ = c.snd_pcm_hw_params_set_format(handle, params,
        c.snd_pcm_format_t.SND_PCM_FORMAT_S16_LE);

    // Two channels (stereo) */
    _ = c.snd_pcm_hw_params_set_channels(handle, params, 2);

    // 44100 bits/second sampling rate (CD quality) */
    val = 44100;
    _ = c.snd_pcm_hw_params_set_rate_near(handle, params,
        &val, &dir);

    // Set period size to 32 frames. */
    frames = 32;
    _ = c.snd_pcm_hw_params_set_period_size_near(handle, params, &frames, &dir);

    // Write the parameters to the driver */
    rc = c.snd_pcm_hw_params(handle, params);
    if (rc < 0) {
        std.log.err("unable to set hw parameters: {s}", .{c.snd_strerror(rc)});
        return;
    }

    // Use a buffer large enough to hold one period */
    _ = c.snd_pcm_hw_params_get_period_size(params, &frames,
        &dir);
    std.log.info("period size: {}", .{frames});
    size = frames * 4; // 2 bytes/sample, 2 channels */

    const alloc = std.heap.page_allocator;
    var buffer = try alloc.alloc(u8, size);
    defer alloc.free(buffer);

    // We want to loop for 5 seconds */
    _ = c.snd_pcm_hw_params_get_period_time(params,
        &val, &dir);
    // 5 seconds in microseconds divided by
    // period time */
    loops = 5000000 / val;
    const stdin = std.io.getStdIn();
    while (loops > 0) {
        loops-=1;
        // read stdin
        //rc = read(0, buffer, size);
        var read = try stdin.read(buffer);
        if (read == 0) {
            std.log.err("end of file on input", .{});
            break;
        } else if (read != size) {
            std.log.err("short read: read {} bytes, should have read {}", .{read, buffer.len});
        }
        
       //var framesw = c.snd_pcm_writei(handle, &buffer, frames);
       var framesw = c.snd_pcm_writei(handle, &buffer[0], frames);
       if (framesw == -c.EPIPE) {
           // EPIPE means underrun */
           std.log.err("underrun occurred", .{});
           _ = c.snd_pcm_prepare(handle);
       } else if (framesw < 0) {
           std.log.err("error from writei: {s}", .{c.snd_strerror(rc)});
       }  else if (framesw != frames) {
           std.log.err("short write, write {} frames", .{rc});
       }
    }

    _ = c.snd_pcm_drain(handle);
    _ = c.snd_pcm_close(handle);

    return;
}