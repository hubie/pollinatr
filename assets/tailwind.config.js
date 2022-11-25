const defaultTheme = require('tailwindcss/defaultTheme')
  module.exports = {
      content: [
        './js/**/*.js',
        '../lib/*_web.ex',
        '../lib/*_web/**/*.*ex'
      ],
      theme: {
        extend: {
          fontFamily: {
            sans: ['Inter var', ...defaultTheme.fontFamily.sans],
          }
        }
      },
      variants: {},
      plugins: [
        require('@tailwindcss/forms'),
        require('@tailwindcss/typography'),
        require('@tailwindcss/aspect-ratio')
      ]
    };