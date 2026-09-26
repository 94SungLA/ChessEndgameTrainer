import CoreText
import SwiftUI

enum AppFont {
    static func register() {
        guard let url = Bundle.main.url(forResource: "SpaceGrotesk-Variable", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    static func title(_ style: Font.TextStyle = .title) -> Font {
        .custom("SpaceGrotesk-Light_Bold", size: baseSize(for: style), relativeTo: style)
    }

    static func number(_ style: Font.TextStyle = .title2) -> Font {
        .custom("SpaceGrotesk-Light_Medium", size: baseSize(for: style), relativeTo: style)
    }

    private static func baseSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline: 17
        default: 17
        }
    }
}
