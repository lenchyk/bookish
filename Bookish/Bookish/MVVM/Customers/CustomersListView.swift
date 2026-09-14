//
//  CustomersListView.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import SwiftUI

struct CustomersListView: View {
  @Bindable var viewModel: CustomersListViewModel

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.customers.isEmpty && viewModel.loadingState.isLoading {
          ProgressView("Loading customers…")
        } else if viewModel.customers.isEmpty, let error = viewModel.loadingState.errorMessage {
          ContentUnavailableView {
            Label("Couldn’t load customers", systemImage: "wifi.slash")
          } description: {
            Text(error)
          } actions: {
            Button("Retry") {
              Task { await viewModel.loadCustomers() }
            }
          }
        } else if viewModel.customers.isEmpty {
          ContentUnavailableView(
            "No customers",
            systemImage: "person.2",
            description: Text("Pull to refresh.")
          )
        } else {
          List(viewModel.customers) { customer in
            VStack(alignment: .leading, spacing: 6) {
              Text(customer.displayName)
                .font(.headline)

              if let email = customer.email, !email.isEmpty {
                Text(email)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }

              if let address = customer.address, !address.isEmpty {
                Text(address)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }

              Text("Preferred currency: \(customer.currency.code)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
          }
        }
      }
      .navigationTitle("Customers")
      .task {
        await viewModel.loadCustomers()
      }
      .refreshable {
        await viewModel.loadCustomers()
      }
    }
  }
}
