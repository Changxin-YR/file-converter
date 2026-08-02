/**
 * 单位换算器页
 * 支持重量、长度、温度、面积、体积等常用单位互转
 * 纯离线计算,无网络依赖。
 */
import { router } from '@kit.ArkUI'
import { AppPageHeader } from '../components/AppPageHeader'
import { MetricInputField } from '../components/MetricInputField'
import { ChipItem, OptionChipGroup } from '../components/OptionChipGroup'
import { UiConstants } from '../common/UiConstants'

interface UnitCategory {
  name: string
  units: UnitItem[]
}

interface UnitItem {
  key: string
  label: string
  toBase: number
}

const CATEGORIES: UnitCategory[] = [
  {
    name: '重量',
    units: [
      { key: 'kg', label: '千克 (kg)', toBase: 1 },
      { key: 'g', label: '克 (g)', toBase: 0.001 },
      { key: 'mg', label: '毫克 (mg)', toBase: 0.000001 },
      { key: 'lbs', label: '磅 (lbs)', toBase: 0.453592 },
      { key: 'oz', label: '盎司 (oz)', toBase: 0.0283495 },
      { key: 'ton', label: '吨 (t)', toBase: 1000 },
      { key: 'jin', label: '斤', toBase: 0.5 }
    ]
  },
  {
    name: '长度',
    units: [
      { key: 'm', label: '米 (m)', toBase: 1 },
      { key: 'km', label: '千米 (km)', toBase: 1000 },
      { key: 'cm', label: '厘米 (cm)', toBase: 0.01 },
      { key: 'mm', label: '毫米 (mm)', toBase: 0.001 },
      { key: 'feet', label: '英尺 (ft)', toBase: 0.3048 },
      { key: 'inch', label: '英寸 (in)', toBase: 0.0254 },
      { key: 'mile', label: '英里 (mi)', toBase: 1609.34 },
      { key: 'yard', label: '码 (yd)', toBase: 0.9144 }
    ]
  },
  {
    name: '面积',
    units: [
      { key: 'sqm', label: '平方米 (m²)', toBase: 1 },
      { key: 'sqkm', label: '平方千米 (km²)', toBase: 1000000 },
      { key: 'ha', label: '公顷 (ha)', toBase: 10000 },
      { key: 'acre', label: '英亩', toBase: 4046.86 },
      { key: 'sqft', label: '平方英尺 (ft²)', toBase: 0.092903 },
      { key: 'mu', label: '亩', toBase: 666.667 }
    ]
  },
  {
    name: '体积',
    units: [
      { key: 'l', label: '升 (L)', toBase: 1 },
      { key: 'ml', label: '毫升 (mL)', toBase: 0.001 },
      { key: 'gal', label: '加仑 (gal)', toBase: 3.78541 },
      { key: 'qt', label: '夸脱 (qt)', toBase: 0.946353 },
      { key: 'cup', label: '杯', toBase: 0.236588 },
      { key: 'cbm', label: '立方米 (m³)', toBase: 1000 }
    ]
  },
  {
    name: '温度',
    units: [
      { key: 'c', label: '摄氏度 (°C)', toBase: 1 },
      { key: 'f', label: '华氏度 (°F)', toBase: 1 },
      { key: 'k', label: '开尔文 (K)', toBase: 1 }
    ]
  },
  {
    name: '速度',
    units: [
      { key: 'mps', label: '米/秒 (m/s)', toBase: 1 },
      { key: 'kmh', label: '千米/时 (km/h)', toBase: 0.277778 },
      { key: 'mph', label: '英里/时 (mph)', toBase: 0.44704 },
      { key: 'knot', label: '节 (kn)', toBase: 0.514444 }
    ]
  },
  {
    name: '时间',
    units: [
      { key: 'sec', label: '秒 (s)', toBase: 1 },
      { key: 'min', label: '分钟 (min)', toBase: 60 },
      { key: 'hr', label: '小时 (h)', toBase: 3600 },
      { key: 'day', label: '天 (d)', toBase: 86400 },
      { key: 'week', label: '周', toBase: 604800 }
    ]
  },
  {
    name: '数据存储',
    units: [
      { key: 'byte', label: '字节 (B)', toBase: 1 },
      { key: 'kb', label: 'KB', toBase: 1024 },
      { key: 'mb', label: 'MB', toBase: 1048576 },
      { key: 'gb', label: 'GB', toBase: 1073741824 },
      { key: 'tb', label: 'TB', toBase: 1099511627776 }
    ]
  }
]

@Entry
@Component
struct UnitConverterPage {
  @State categoryIndex: number = 0
  @State fromIndex: number = 0
  @State toIndex: number = 1
  @State inputValue: string = ''
  @State result: string = ''
  @State categoryColumns: string = '1fr 1fr'

  build() {
    Navigation() {
      Column() {
        AppPageHeader({ title: '单位换算器', onBack: () => router.back() })
          .padding({ left: 4, right: 16 })
        Scroll() {
          Column({ space: UiConstants.SECTION_GAP }) {
            this.CategorySection()
            this.InputSection()
            this.UnitPickerSection()
            this.ResultSection()
          }
          .width('100%')
          .constraintSize({ maxWidth: UiConstants.CONTENT_MAX_WIDTH })
          .padding({ left: UiConstants.PAGE_PADDING_PHONE, right: UiConstants.PAGE_PADDING_PHONE, bottom: 24 })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.updateResponsiveLayout(Number(newValue.width))
      })
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }

  @Builder
  CategorySection() {
    Column({ space: 8 }) {
      Text('换算类型')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Grid() {
        ForEach(CATEGORIES, (cat: UnitCategory, index: number) => {
          GridItem() {
            Row() {
              Text(cat.name)
                .fontSize(14)
                .fontWeight(this.categoryIndex === index ? FontWeight.Medium : FontWeight.Normal)
                .fontColor(this.categoryIndex === index ? Color.White : $r('app.color.text_primary'))
            }
            .width('100%')
            .height(52)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.categoryIndex === index ? $r('app.color.brand_primary') : $r('app.color.surface_primary'))
            .borderRadius(UiConstants.CONTROL_RADIUS)
            .border({ width: 1, color: this.categoryIndex === index ? $r('app.color.brand_primary') : $r('app.color.border_subtle') })
            .onClick(() => this.selectCategory(index))
          }
        }, (cat: UnitCategory, index: number) => `${cat.name}_${index}`)
      }
      .columnsTemplate(this.categoryColumns)
      .columnsGap(10)
      .rowsGap(10)
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InputSection() {
    MetricInputField({
      label: '输入数值',
      value: this.inputValue,
      placeholder: '请输入数值',
      suffix: '',
      isEnabled: true,
      onChange: (value: string) => {
        this.inputValue = value
        this.calculate()
      }
    })
  }

  @Builder
  UnitPickerSection() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('从')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        OptionChipGroup({
          items: this.getUnitChips(),
          selectedKey: this.getCurrentUnits()[this.fromIndex].key,
          disabled: false,
          onSelect: (key: string) => {
            this.fromIndex = this.findUnitIndex(key)
            this.calculate()
          }
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Text('转换为')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        OptionChipGroup({
          items: this.getUnitChips(),
          selectedKey: this.getCurrentUnits()[this.toIndex].key,
          disabled: false,
          onSelect: (key: string) => {
            this.toIndex = this.findUnitIndex(key)
            this.calculate()
          }
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  ResultSection() {
    if (this.result.length > 0) {
      Column({ space: 8 }) {
        Text('换算结果')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Row() {
          Text(this.result)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.result.startsWith('请输入') ? $r('app.color.error') : $r('app.color.brand_primary'))
        }
        .width('100%')
        .padding(16)
        .borderRadius(UiConstants.CARD_RADIUS)
        .backgroundColor($r('app.color.surface_primary'))
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  private getCurrentUnits(): UnitItem[] {
    return CATEGORIES[this.categoryIndex].units
  }

  private getUnitChips(): ChipItem[] {
    return this.getCurrentUnits().map((unit: UnitItem) => {
      const chip: ChipItem = { key: unit.key, label: unit.label, enabled: true, developing: false }
      return chip
    })
  }

  private findUnitIndex(key: string): number {
    const units = this.getCurrentUnits()
    for (let index = 0; index < units.length; index++) {
      if (units[index].key === key) {
        return index
      }
    }
    return 0
  }

  private selectCategory(index: number): void {
    this.categoryIndex = index
    this.fromIndex = 0
    this.toIndex = 1
    this.calculate()
  }

  private updateResponsiveLayout(width: number): void {
    this.categoryColumns = width >= UiConstants.BREAKPOINT_MEDIUM ? '1fr 1fr 1fr 1fr' : '1fr 1fr'
  }

  private calculate(): void {
    if (this.inputValue.length === 0) {
      this.result = ''
      return
    }
    const value = parseFloat(this.inputValue)
    if (isNaN(value)) {
      this.result = '请输入有效数值'
      return
    }
    const units = this.getCurrentUnits()
    const from = units[this.fromIndex]
    const to = units[this.toIndex]
    const category = CATEGORIES[this.categoryIndex]

    let converted: number
    if (category.name === '温度') {
      converted = this.convertTemperature(value, from.key, to.key)
    } else {
      const baseValue = value * from.toBase
      converted = baseValue / to.toBase
    }

    const formatted = converted % 1 === 0 ? converted.toString() : converted.toFixed(6).replace(/0+$/, '').replace(/\.$/, '')
    this.result = `${this.inputValue} ${from.label} = ${formatted} ${to.label}`
  }

  private convertTemperature(value: number, fromKey: string, toKey: string): number {
    let celsius: number
    switch (fromKey) {
      case 'c':
        celsius = value
        break
      case 'f':
        celsius = (value - 32) * 5 / 9
        break
      case 'k':
        celsius = value - 273.15
        break
      default:
        celsius = value
    }
    switch (toKey) {
      case 'c':
        return celsius
      case 'f':
        return celsius * 9 / 5 + 32
      case 'k':
        return celsius + 273.15
      default:
        return celsius
    }
  }
}
