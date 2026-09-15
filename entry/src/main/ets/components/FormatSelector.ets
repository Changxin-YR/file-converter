import { FormatInfo } from '../common/FormatTypes'
import { ChipItem, OptionChipGroup } from './OptionChipGroup'

@Component
export struct FormatSelector {
  @Prop formats: FormatInfo[] = []
  @Prop selected: string = ''
  @Prop disabled: boolean = false
  selectCallback: (extension: string) => void = (_ext: string) => {}

  build() {
    OptionChipGroup({
      items: this.getChipItems(),
      selectedKey: this.selected,
      disabled: this.disabled,
      onSelect: (extension: string) => {
        this.selectCallback(extension)
      }
    })
  }

  private getChipItems(): ChipItem[] {
    const items: ChipItem[] = []
    for (const format of this.formats) {
      items.push({
        key: format.extension,
        label: format.displayName,
        enabled: format.nativeSupported
      })
    }
    return items
  }
}
