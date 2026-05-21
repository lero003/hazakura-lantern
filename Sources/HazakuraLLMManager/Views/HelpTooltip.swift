import SwiftUI

struct HelpTooltip: View {
    let title: String
    let description: String
    let tips: String

    @Environment(\.locale) private var locale
    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover = true
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(explanationLabel)
        .help(explanationLabel)
        .popover(isPresented: $isShowingPopover, arrowEdge: .trailing) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("説明 / Description")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tips")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)

                    Text(tips)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            .padding(14)
            .frame(width: 320)
        }
    }

    private var explanationLabel: String {
        String(
            localized: String.LocalizationValue("Show explanation for \(title)"),
            bundle: .module,
            locale: locale
        )
    }
}

// プリセットデータの整理
extension HelpTooltip {
    static func runtime() -> HelpTooltip {
        HelpTooltip(
            title: "実行環境 / Runtime (llama-server)",
            description: "llama-server の実行バイナリを指定します。これは、モデルを実行してローカルサーバーを起動する核となるプログラム（推論エンジン）です。",
            tips: "llama.cpp から自身でビルドしたバイナリ、またはHomebrew等でインストールされた llama-server の実行ファイルパスを選択してください。"
        )
    }

    static func model() -> HelpTooltip {
        HelpTooltip(
            title: "モデル / Model (GGUF)",
            description: "使用するLLMのモデルデータファイル（.gguf 形式）を指定します。",
            tips: "GGUF形式は、CPUやGPUで高速に推論を実行するために量子化 / Quantization（軽量化）されたフォーマットです。Hugging Faceなどで入手した .gguf ファイルを選択してください。"
        )
    }

    static func port() -> HelpTooltip {
        HelpTooltip(
            title: "ポート番号 / Port",
            description: "起動したローカルサーバーがリクエストを待ち受けるネットワークポートです。",
            tips: "外部のチャットクライアントやアプリから接続する際のアドレス（例: http://localhost:1234）の一部になります。通常はデフォルトの 1234 のままで構いません。他のサービスと重複して起動できない場合は、空いている別のポートを指定してください。"
        )
    }

    static func contextSize() -> HelpTooltip {
        HelpTooltip(
            title: "コンテキストサイズ / Context Size",
            description: "モデルが一度に処理・記憶できる最大トークン数（文脈の長さ / Context Window Size）です。",
            tips: "llama-server では 0 を指定するとモデルから読み込まれますが、Lantern では明示値だけを扱います。近年のモデルは 128K 以上の文脈を持つものもあります。大きい値ほどRAM / VRAMを使うため、選択したモデルとマシンに合わせて調整してください。"
        )
    }

    static func threads() -> HelpTooltip {
        HelpTooltip(
            title: "CPUスレッド数 / CPU Threads",
            description: "演算処理に使用するCPUのスレッド数です。",
            tips: "auto の場合、Lantern は -t を渡さず llama-server 側の既定に任せます。Lantern はまだCPUコア数を自動測定していません。手動指定は実機で速度と安定性を見ながら調整してください。"
        )
    }

    static func gpuLayers() -> HelpTooltip {
        HelpTooltip(
            title: "GPUレイヤー数 / GPU Layers",
            description: "ニューラルネットワークのレイヤーのうち、いくつをGPUに処理させる（オフロード / Offloading する）かを指定します。",
            tips: "auto の場合、Lantern は -ngl を渡さず llama-server 側の既定に任せます。Lantern はまだGPU容量やモデル層数を自動測定していません。0 はCPUのみ、手動値は選択したモデルとメモリ量に合わせて調整してください。"
        )
    }

    static func additionalArguments() -> HelpTooltip {
        HelpTooltip(
            title: "追加の起動引数 / Additional Arguments",
            description: "llama-server に直接渡す任意の追加オプション引数です。",
            tips: "開発者向けの高度な設定用です。例えば、デバッグ出力を増やす場合は -v や --verbose、特殊なサンプリングパラメータなどをスペース区切りで記述します。"
        )
    }
}
