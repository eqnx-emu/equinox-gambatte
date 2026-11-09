#pragma once

#include <cstdint>
#include <string>
#include <variant>
#include <vector>

enum class RomError { None, NotFound, Unreadable, NoRomInZip, Unsupported, TooBig };

struct Rom {
    std::vector<uint8_t> data;
    std::string innerName;  // entry name when loaded from an archive, empty otherwise
};

// .gbc/.gb are read whole; for .zip and .7z the first .gbc/.gb entry in archive order.
// Limits, checked before reading: 8 MiB for the ROM (the largest Game Boy Color ROM is 8 MiB)
// and 16 MiB for an archive; bigger gives TooBig.
std::variant<Rom, RomError> loadRom(const std::string& path);
