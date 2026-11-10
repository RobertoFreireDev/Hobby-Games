#pragma once
// Small replacements for <utility>/<algorithm>, which the freestanding toolchain lacks.
// Forced inline so Debug (-Og) builds do not pay a call for each one.
#define UTIL_INLINE __attribute__((always_inline)) inline
namespace util {
template <typename T> UTIL_INLINE constexpr T min(T a, T b) { return b < a ? b : a; }
template <typename T> UTIL_INLINE constexpr T max(T a, T b) { return a < b ? b : a; }
template <typename T> UTIL_INLINE constexpr T clamp(T v, T lo, T hi) { return v < lo ? lo : (hi < v ? hi : v); }
template <typename T> UTIL_INLINE constexpr T abs(T v) { return v < T(0) ? -v : v; }
template <typename T> UTIL_INLINE constexpr T&& move(T& v) { return static_cast<T&&>(v); }
template <typename T> UTIL_INLINE constexpr void swap(T& a, T& b) { T t = static_cast<T&&>(a); a = static_cast<T&&>(b); b = static_cast<T&&>(t); }

// Signed difference b - a between two angles (4096 = 360 deg), in -2048..2047.
UTIL_INLINE constexpr int angleDiff(int a, int b) { return ((b - a + 2048) & 4095) - 2048; }
}  // namespace util
