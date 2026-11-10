#pragma once
#include <cstdint>
// Inlined even at -Og (Debug): a call per fixed-point operation would dominate physics code.
#define FX_INLINE __attribute__((always_inline)) inline

struct fx {                       // 20.12 fixed point, same scale as the GTE (ONE = 4096)
    int32_t raw = 0;
    static constexpr int SHIFT = 12;
    FX_INLINE static constexpr fx fromRaw(int32_t r) { fx f; f.raw = r; return f; }
    FX_INLINE static constexpr fx fromInt(int i)     { return fromRaw(i << SHIFT); }
    FX_INLINE constexpr int toInt() const            { return raw >> SHIFT; }
    FX_INLINE constexpr fx operator+(fx o) const     { return fromRaw(raw + o.raw); }
    FX_INLINE constexpr fx operator-(fx o) const     { return fromRaw(raw - o.raw); }
    FX_INLINE constexpr fx operator-() const         { return fromRaw(-raw); }
    FX_INLINE constexpr fx operator*(fx o) const     { return fromRaw(int32_t((int64_t(raw) * o.raw) >> SHIFT)); }
    FX_INLINE constexpr fx operator/(fx o) const     { return fromRaw(int32_t((int64_t(raw) << SHIFT) / o.raw)); }  // slow (64-bit div)
    FX_INLINE constexpr fx operator*(int i) const    { return fromRaw(raw * i); }
    FX_INLINE constexpr fx operator/(int i) const    { return fromRaw(raw / i); }
    FX_INLINE fx& operator+=(fx o) { raw += o.raw; return *this; }
    FX_INLINE fx& operator-=(fx o) { raw -= o.raw; return *this; }
    FX_INLINE constexpr bool operator==(fx o) const  { return raw == o.raw; }
    FX_INLINE constexpr bool operator!=(fx o) const  { return raw != o.raw; }
    FX_INLINE constexpr bool operator<(fx o) const   { return raw < o.raw; }
    FX_INLINE constexpr bool operator<=(fx o) const  { return raw <= o.raw; }
    FX_INLINE constexpr bool operator>(fx o) const   { return raw > o.raw; }
    FX_INLINE constexpr bool operator>=(fx o) const  { return raw >= o.raw; }
};
consteval fx operator""_fx(long double v)        { return fx::fromRaw(int32_t(v * 4096.0L)); }
consteval fx operator""_fx(unsigned long long v) { return fx::fromInt(int(v)); }

struct Vec3 {                     // 3D vector of fx (world units, Y points DOWN like the GTE)
    fx x, y, z;
    FX_INLINE constexpr Vec3 operator+(const Vec3& o) const { return {x + o.x, y + o.y, z + o.z}; }
    FX_INLINE constexpr Vec3 operator-(const Vec3& o) const { return {x - o.x, y - o.y, z - o.z}; }
    FX_INLINE constexpr Vec3 operator*(fx s) const          { return {x * s, y * s, z * s}; }
    FX_INLINE Vec3& operator+=(const Vec3& o) { x += o.x; y += o.y; z += o.z; return *this; }
    FX_INLINE Vec3& operator-=(const Vec3& o) { x -= o.x; y -= o.y; z -= o.z; return *this; }
    FX_INLINE constexpr fx dot(const Vec3& o) const         { return x * o.x + y * o.y + z * o.z; }
};

struct Rng {                      // xorshift32
    uint32_t s = 0x12345678u;
    uint32_t next()           { s ^= s << 13; s ^= s >> 17; s ^= s << 5; return s; }
    int range(int lo, int hi) { return lo + int(next() % uint32_t(hi - lo + 1)); }
};
