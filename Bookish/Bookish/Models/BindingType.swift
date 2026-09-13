//
//  BindingType.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.09.2026.
//

import Foundation

enum BindingType: String, Codable, CaseIterable, Hashable {
  case hardcover
  case paperback
  case kindleEdition = "kindle edition"
  case massMarketPaperback = "mass market paperback"

  init(from decoder: Decoder) throws {
    self = try FlexibleEnumDecoding.value(from: decoder)
  }

  var displayName: String {
    rawValue.capitalized
  }
}
