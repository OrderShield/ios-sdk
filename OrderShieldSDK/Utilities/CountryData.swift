//
//  CountryData.swift
//  OrderShieldSDK
//
//  Created by rajkumar on 16/01/26.
//

import Foundation

@available(iOS 13.0, *)
struct Country {
    let name: String
    let code: String
    let dialCode: String
    let flag: String
}

@available(iOS 13.0, *)
class CountryData {
    static let countries: [Country] = [
        Country(name: "United States", code: "US", dialCode: "+1", flag: "🇺🇸"),
        Country(name: "United Kingdom", code: "GB", dialCode: "+44", flag: "🇬🇧"),
        Country(name: "Canada", code: "CA", dialCode: "+1", flag: "🇨🇦"),
        Country(name: "Australia", code: "AU", dialCode: "+61", flag: "🇦🇺"),
        Country(name: "Germany", code: "DE", dialCode: "+49", flag: "🇩🇪"),
        Country(name: "France", code: "FR", dialCode: "+33", flag: "🇫🇷"),
        Country(name: "Italy", code: "IT", dialCode: "+39", flag: "🇮🇹"),
        Country(name: "Spain", code: "ES", dialCode: "+34", flag: "🇪🇸"),
        Country(name: "India", code: "IN", dialCode: "+91", flag: "🇮🇳"),
        Country(name: "China", code: "CN", dialCode: "+86", flag: "🇨🇳"),
        Country(name: "Japan", code: "JP", dialCode: "+81", flag: "🇯🇵"),
        Country(name: "Brazil", code: "BR", dialCode: "+55", flag: "🇧🇷"),
        Country(name: "Mexico", code: "MX", dialCode: "+52", flag: "🇲🇽"),
        Country(name: "Russia", code: "RU", dialCode: "+7", flag: "🇷🇺"),
        Country(name: "South Korea", code: "KR", dialCode: "+82", flag: "🇰🇷"),
        Country(name: "Netherlands", code: "NL", dialCode: "+31", flag: "🇳🇱"),
        Country(name: "Sweden", code: "SE", dialCode: "+46", flag: "🇸🇪"),
        Country(name: "Norway", code: "NO", dialCode: "+47", flag: "🇳🇴"),
        Country(name: "Denmark", code: "DK", dialCode: "+45", flag: "🇩🇰"),
        Country(name: "Finland", code: "FI", dialCode: "+358", flag: "🇫🇮"),
        Country(name: "Poland", code: "PL", dialCode: "+48", flag: "🇵🇱"),
        Country(name: "Turkey", code: "TR", dialCode: "+90", flag: "🇹🇷"),
        Country(name: "Saudi Arabia", code: "SA", dialCode: "+966", flag: "🇸🇦"),
        Country(name: "United Arab Emirates", code: "AE", dialCode: "+971", flag: "🇦🇪"),
        Country(name: "Singapore", code: "SG", dialCode: "+65", flag: "🇸🇬"),
        Country(name: "Malaysia", code: "MY", dialCode: "+60", flag: "🇲🇾"),
        Country(name: "Indonesia", code: "ID", dialCode: "+62", flag: "🇮🇩"),
        Country(name: "Philippines", code: "PH", dialCode: "+63", flag: "🇵🇭"),
        Country(name: "Thailand", code: "TH", dialCode: "+66", flag: "🇹🇭"),
        Country(name: "Vietnam", code: "VN", dialCode: "+84", flag: "🇻🇳"),
        Country(name: "South Africa", code: "ZA", dialCode: "+27", flag: "🇿🇦"),
        Country(name: "Argentina", code: "AR", dialCode: "+54", flag: "🇦🇷"),
        Country(name: "Chile", code: "CL", dialCode: "+56", flag: "🇨🇱"),
        Country(name: "Colombia", code: "CO", dialCode: "+57", flag: "🇨🇴"),
        Country(name: "Peru", code: "PE", dialCode: "+51", flag: "🇵🇪"),
        Country(name: "New Zealand", code: "NZ", dialCode: "+64", flag: "🇳🇿"),
        Country(name: "Ireland", code: "IE", dialCode: "+353", flag: "🇮🇪"),
        Country(name: "Switzerland", code: "CH", dialCode: "+41", flag: "🇨🇭"),
        Country(name: "Austria", code: "AT", dialCode: "+43", flag: "🇦🇹"),
        Country(name: "Belgium", code: "BE", dialCode: "+32", flag: "🇧🇪"),
        Country(name: "Portugal", code: "PT", dialCode: "+351", flag: "🇵🇹"),
        Country(name: "Greece", code: "GR", dialCode: "+30", flag: "🇬🇷"),
        Country(name: "Israel", code: "IL", dialCode: "+972", flag: "🇮🇱"),
        Country(name: "Egypt", code: "EG", dialCode: "+20", flag: "🇪🇬"),
        Country(name: "Nigeria", code: "NG", dialCode: "+234", flag: "🇳🇬"),
        Country(name: "Kenya", code: "KE", dialCode: "+254", flag: "🇰🇪"),
        Country(name: "Pakistan", code: "PK", dialCode: "+92", flag: "🇵🇰"),
        Country(name: "Bangladesh", code: "BD", dialCode: "+880", flag: "🇧🇩"),
        Country(name: "Sri Lanka", code: "LK", dialCode: "+94", flag: "🇱🇰"),
    ]
    
    static func getDefaultCountry() -> Country {
        return countries.first { $0.code == "US" } ?? countries[0]
    }
}

