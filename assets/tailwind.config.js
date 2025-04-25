// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const defaultTheme = require("tailwindcss/defaultTheme")
const colors = require("tailwindcss/colors")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        ...colors,
        brand: "#a6da95"
      },
      fontFamily: {
        mono: ['Menlo', 'Monaco', 'Courier New', 'monospace'],
        sans: [
          'Segoe UI',
                  ],
        serif: ['Georgia', 'Cambria', 'Times New Roman', 'Times', 'serif'],
        display: ['Oswald'],
        body: ['"Open Sans"']
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
      boxShadow: {
        sm: '0 0 2px 0 rgb(0 0 0 / 0.05)',
        DEFAULT: '0 0 3px 0 rgb(0 0 0 / 0.1)',
        md: '0 0 6px -1px rgb(0 0 0 / 0.1)',
        lg: '0 0 15px -3px rgb(0 0 0 / 0.1)',
        xl: '0 0 20px -6px rgb(0 0 0 / 0.1)',
        '2xl': '0 0 50px -12px rgb(0 0 0 / 0.25)',
        inner: 'inset 0 0 4px 0 rgb(0 0 0 / 0.05)',
        none: '0 0 #0000'
      }
    }
  },
  plugins: [
    require("@tailwindcss/forms"),
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"]))
  ]
}
