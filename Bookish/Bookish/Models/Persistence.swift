//
//  Persistence.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation
import SwiftData

enum Persistence {
  static let schema = Schema([
    BookCache.self,
    AuthorCache.self,
    GenreCache.self,
    CurrencyCache.self,
    BookPriceCache.self,
    CustomerCache.self,
    OrderCache.self,
    OrderItemCache.self
  ])

  static func makeContainer() -> ModelContainer {
    let storeURL = storeURL()
    let configuration = ModelConfiguration(
      schema: schema,
      url: storeURL
    )

    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      destroyStore(at: storeURL)

      do {
        return try ModelContainer(for: schema, configurations: [configuration])
      } catch {
        fatalError("Could not create ModelContainer: \(error)")
      }
    }
  }

  private static func storeURL() -> URL {
    let supportDirectory = URL.applicationSupportDirectory
    try? FileManager.default.createDirectory(
      at: supportDirectory,
      withIntermediateDirectories: true
    )
    return supportDirectory.appending(path: "BookishCache.store")
  }

  private static func destroyStore(at url: URL) {
    let fileManager = FileManager.default
    let relatedURLs = [
      url,
      URL(fileURLWithPath: url.path + "-wal"),
      URL(fileURLWithPath: url.path + "-shm")
    ]

    for relatedURL in relatedURLs {
      try? fileManager.removeItem(at: relatedURL)
    }
  }
}
