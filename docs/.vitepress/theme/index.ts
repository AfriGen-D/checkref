import DefaultTheme from 'vitepress/theme'
import './style.css'

export default {
  ...DefaultTheme,
  enhanceApp({ app }) {
    // You can register global components here if needed
    // app.component('MyCustomComponent', MyCustomComponent)
  }
}