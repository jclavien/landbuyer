// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    colors: {
      white: '#ffffff',
      black: '#000000',
      transparent: 'transparent',
      gray: {
        25: 'rgb(202, 211, 245)',
        50: 'rgb(184, 192, 224)',
        75: 'rgb(165, 173, 203)',
        100: 'rgb(147, 154, 183)',
        200: 'rgb(128, 135, 162)',
        300: 'rgb(110, 115, 141)',
        400: 'rgb(91, 96, 120)',
        500: 'rgb(73, 77, 100)',
        600: 'rgb(54, 58, 79)',
        700: 'rgb(36, 39, 58)',
        800: 'rgb(30, 32, 48)',
        900: 'rgb(24, 25, 38)',
        950: 'rgb(16, 16, 26)',
      },
      red: '#d64f63',
      yellow: '#eed49f',
      green: '#a6da95',
    },
    fontFamily: {
      mono: ['Menlo', 'Monaco', 'Courier New', 'monospace'],
    },
    fontSize: {
      xs: '0.625rem',
      sm: '0.75rem',
      base: '0.875rem',
      lg: '1rem',
      xl: '1.125rem',
      '2xl': '1.25rem',
      '3xl': '1.5rem',
      '4xl': '1.75rem',
      '5xl': '2rem'
    },
    extend: {
      colors: {
        brand: "#a6da95",
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
  ]
}
