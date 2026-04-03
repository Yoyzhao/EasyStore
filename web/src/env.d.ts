declare module '*.vue' {
  import type { DefineComponent } from 'vue'

  const component: DefineComponent<Record<string, unknown>, Record<string, unknown>, unknown>
  export default component
}

declare module 'vue-cropper' {
    import { DefineComponent } from 'vue'
    const VueCropper: DefineComponent<{}, {}, any>
    export { VueCropper }
    export default VueCropper
}
