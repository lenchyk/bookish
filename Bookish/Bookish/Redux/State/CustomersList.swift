//
//  CustomersList.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct CustomersList: Equatable {
  var ids: [Customer.ID] = []
  var loadingState: LoadingState = .idle
}
