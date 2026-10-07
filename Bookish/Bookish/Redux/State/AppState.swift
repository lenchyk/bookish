//
//  AppState.swift
//  Bookish
//
//  Created by Soroka, Olena on 04.10.2026.
//

import Foundation

struct AppState: Equatable {
  var books = Books()
  var booksList: BooksList = .idle
  var bookSearch: BookSearch = .search("")
  var authors = Authors()
  var genres = Genres()
  var bookGenres = BookGenres()
  var currencies = Currencies()
  var customers = Customers()
  var customersList = CustomersList()
  var orders = Orders()
  var ordersList = OrdersList()
  var orderDetails = OrderDetails()
}
