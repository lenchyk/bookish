//
//  APIConfiguration.swift
//  Bookish
//
//  Created by Soroka, Olena on 30.08.2026.
//

import Foundation

enum APIError: Error, Equatable {
  case badURL
  case httpStatus(Int)
}

enum APIConfiguration {
  static var baseURL: URL {
    if let string = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
       let url = URL(string: string),
       !string.isEmpty {
      return url
    }
    return URL(string: "http://localhost:3000")!
  }
}

enum BookishPaging {
  static let pageSize = 50
}
