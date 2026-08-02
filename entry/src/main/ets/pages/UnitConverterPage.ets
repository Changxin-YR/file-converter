/**
 * 单位换算器页
 * 支持重量、长度、温度、面积、体积等常用单位互转
 * 纯离线计算,无网络依赖。
 */
import { promptAction } from '@kit.ArkUI'

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

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 16 }) {
          this.CategorySection()
          this.InputSection()
          this.UnitPickerSection()
          this.ResultSection()
        }
        .width('100%')
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .mode(NavigationMode.Stack)
    .title('单位换算器')
    .titleMode(NavigationTitleMode.Mini)
  }

  @Builder
  CategorySection() {
    Column({ space: 8 }) {
      Text('换算类型')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(CATEGORIES, (cat: UnitCategory, index: number) => {
          Text(cat.name)
            .fontSize(14)
            .fontColor(this.categoryIndex === index ? Color.White : $r('app.color.text_primary'))
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .borderRadius(18)
            .backgroundColor(this.categoryIndex === index ? $r('app.color.primary') : $r('app.color.chip_background'))
            .margin({ top: 6, right: 8 })
            .onClick(() => {
              this.categoryIndex = index
              this.fromIndex = 0
              this.toIndex = 1
              this.calculate()
            })
        }, (cat: UnitCategory, index: number) => `${cat.name}_${index}`)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  InputSection() {
    Column({ space: 8 }) {
      Text('输入数值')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)

      TextInput({ placeholder: '请输入数值', text: this.inputValue })
        .type(InputType.Number)
        .width('100%')
        .height(44)
        .onChange((value: string) => {
          this.inputValue = value
          this.calculate()
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  UnitPickerSection() {
    Column({ space: 12 }) {
      Column({ space: 6 }) {
        Text('从')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getCurrentUnits(), (unit: UnitItem, index: number) => {
            Text(unit.label)
              .fontSize(13)
              .fontColor(this.fromIndex === index ? Color.White : $r('app.color.text_primary'))
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .borderRadius(16)
              .backgroundColor(this.fromIndex === index ? $r('app.color.primary') : $r('app.color.chip_background'))
              .margin({ top: 6, right: 6 })
              .onClick(() => {
                this.fromIndex = index
                this.calculate()
              })
          }, (unit: UnitItem, index: number) => `from_${unit.key}_${index}`)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 6 }) {
        Text('转换为')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.getCurrentUnits(), (unit: UnitItem, index: number) => {
            Text(unit.label)
              .fontSize(13)
              .fontColor(this.toIndex === index ? Color.White : $r('app.color.text_primary'))
              .padding({ left: 12, right: 12, top: 5, bottom: 5 })
              .borderRadius(16)
              .backgroundColor(this.toIndex === index ? $r('app.color.primary') : $r('app.color.chip_background'))
              .margin({ top: 6, right: 6 })
              .onClick(() => {
                this.toIndex = index
                this.calculate()
              })
          }, (unit: UnitItem, index: number) => `to_${unit.key}_${index}`)
        }
        .width('100%')
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

        Row() {
          Text(this.result)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary'))
        }
        .width('100%')
        .padding(16)
        .borderRadius(12)
        .backgroundColor($r('app.color.card_background'))
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
  }

  private getCurrentUnits(): UnitItem[] {
    return CATEGORIES[this.categoryIndex].units
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
