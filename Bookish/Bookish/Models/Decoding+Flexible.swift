//
//  Decoding+Flexible.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation

enum APIJSON {
  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .custom(decodeDate)
    return decoder
  }()

  static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
  }()

  private static let isoWithFraction: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let iso: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  private static let posixSpace = posixFormatter(format: "yyyy-MM-dd HH:mm:ss")
  private static let posixT = posixFormatter(format: "yyyy-MM-dd'T'HH:mm:ss")

  private static func posixFormatter(format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = format
    return formatter
  }

  private static func decodeDate(from decoder: Decoder) throws -> Date {
    let container = try decoder.singleValueContainer()
    let string = try container.decode(String.self)

    if let date = isoWithFraction.date(from: string) {
      return date
    }
    if let date = iso.date(from: string) {
      return date
    }
    if let date = posixSpace.date(from: string) {
      return date
    }
    if let date = posixT.date(from: string) {
      return date
    }

    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Unrecognized date format: \(string)"
    )
  }
}

extension KeyedDecodingContainer {
  func decodeFlexibleDecimal(forKey key: Key) throws -> Decimal? {
    if let value = try? decodeIfPresent(Decimal.self, forKey: key) {
      return value
    }
    if let value = try? decodeIfPresent(Double.self, forKey: key) {
      return Decimal(value)
    }
    if let value = try? decodeIfPresent(Int.self, forKey: key) {
      return Decimal(value)
    }
    if let value = try? decodeIfPresent(String.self, forKey: key) {
      return Decimal(string: value)
    }
    return nil
  }
}

enum PriceFormatter {
  private static var formatters: [String: NumberFormatter] = [:]

  static func string(price: Decimal, currency: Currency?) -> String {
    let formatter = formatter(for: currency)

    if let formatted = formatter.string(from: price as NSDecimalNumber) {
      return formatted
    }

    if let symbol = currency?.symbol, !symbol.isEmpty {
      return "\(price) \(symbol)"
    }
    if let code = currency?.code, !code.isEmpty {
      return "\(price) \(code)"
    }
    return "\(price)"
  }

  private static func formatter(for currency: Currency?) -> NumberFormatter {
    let key = "\(currency?.code ?? "")|\(currency?.symbol ?? "")"
    if let existing = formatters[key] {
      return existing
    }

    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    if let code = currency?.code, !code.isEmpty {
      formatter.currencyCode = code
    }
    if let symbol = currency?.symbol, !symbol.isEmpty {
      formatter.currencySymbol = symbol
    }
    formatters[key] = formatter
    return formatter
  }
}
