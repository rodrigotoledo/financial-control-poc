/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        dark: {
          DEFAULT: '#181A1B', // dark grey background
          surface: '#232526', // slightly lighter for panels
          line: '#2C2F31',
        },
        yellowgreen: {
          DEFAULT: '#B6E23A', // yellow-green accent
          dark: '#A2C523',
        },
        ink: '#E9F1E6', // light text for dark bg
      },
    },
  },
  plugins: [],
}
