// Runtime pieces libc++ normally ships prebuilt in libc++.a. There's no such
// library for the i386-xbox target, so provide the handful we need here:
// the forced std::string instantiation plus a few out-of-line helpers.
// Compile this in libc++ mode (OXDK_LIBCXX=1) alongside the rest of the app.
#include <cstddef>
#include <string>

// std::string members are declared `extern template` (expected from the
// dylib). Instantiate them here so they resolve at link time.
template class std::basic_string<char>;

namespace std {
inline namespace __1 {

// unordered_map bucket sizing. A plain next-prime is enough.
size_t __next_prime(size_t __n) {
    if (__n <= 2)
        return 2;
    __n |= 1;
    for (;; __n += 2) {
        bool __prime = true;
        for (size_t __i = 3; __i * __i <= __n; __i += 2) {
            if (__n % __i == 0) {
                __prime = false;
                break;
            }
        }
        if (__prime)
            return __n;
    }
}

// Under -fno-exceptions libc++ routes throws and failed assertions here.
[[noreturn]] void __libcpp_verbose_abort(const char*, ...) noexcept { __builtin_trap(); }

// std::to_string is declared in <string> but defined in libc++.a. Provide the
// integer overloads here, built without any CRT formatting calls.
namespace {
template <class U>
basic_string<char> uint_to_string(U v, bool neg) {
    char buf[24];
    int i = static_cast<int>(sizeof(buf));
    do {
        buf[--i] = static_cast<char>('0' + (v % 10));
        v /= 10;
    } while (v != 0);
    if (neg) {
        buf[--i] = '-';
    }
    return basic_string<char>(&buf[i], sizeof(buf) - i);
}
} // namespace

string to_string(int v) { return uint_to_string(v < 0 ? 0u - static_cast<unsigned>(v) : static_cast<unsigned>(v), v < 0); }
string to_string(unsigned v) { return uint_to_string(v, false); }
string to_string(long v) { return uint_to_string(v < 0 ? 0ul - static_cast<unsigned long>(v) : static_cast<unsigned long>(v), v < 0); }
string to_string(unsigned long v) { return uint_to_string(v, false); }
string to_string(long long v) { return uint_to_string(v < 0 ? 0ull - static_cast<unsigned long long>(v) : static_cast<unsigned long long>(v), v < 0); }
string to_string(unsigned long long v) { return uint_to_string(v, false); }

} // namespace __1
} // namespace std

// C++14 sized delete; the XDK CRT ships only the unsized operator delete.
void operator delete(void* __p, std::size_t) noexcept { ::operator delete(__p); }
