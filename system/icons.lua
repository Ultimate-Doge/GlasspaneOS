-- ============================================
-- GlasspaneOS Icon System
-- ============================================

local Icons = {}

-- ============================================
-- Create custom icons easily
-- ============================================

function Icons.make(lines, primary, secondary)

    return {
        lines = lines,
        primary = primary or colors.white,
        secondary = secondary or colors.lightGray
    }
end

-- ============================================
-- Built-in icons
-- ============================================

Icons.file = Icons.make(
    {
        "##+",
        "###",
        "###"
    },
    colors.white,
    colors.gray
)

Icons.folder = Icons.make(
    {
        "++#",
        "###",
        "###"
    },
    colors.yellow,
    colors.orange
)

Icons.program = Icons.make(
    {
        "###",
        "#.#",
        "###"
    },
    colors.cyan,
    colors.lightBlue
)

Icons.note = Icons.make(
    {
        "###",
        "#++",
        "###"
    },
    colors.white,
    colors.yellow
)

Icons.lua = Icons.make(
    {
        "###",
        "#+#",
        "###"
    },
    colors.blue,
    colors.lightBlue
)

-- ============================================
-- Character to colour
-- ============================================

function Icons.getColour(icon, char)

    if char == "#" then
        return icon.primary
    end

    if char == "+" then
        return icon.secondary
    end

    return nil
end

return Icons
