//
//  OrdersListView.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import SwiftUI

struct OrdersListView: View {
  @Bindable var viewModel: OrdersListViewModel

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.orders.isEmpty && viewModel.loadingState.isLoading {
          ProgressView("Loading orders…")
        } else if viewModel.orders.isEmpty, let error = viewModel.loadingState.errorMessage {
          ContentUnavailableView {
            Label("Couldn’t load orders", systemImage: "wifi.slash")
          } description: {
            Text(error)
          } actions: {
            Button("Retry") {
              Task { await viewModel.loadOrders() }
            }
          }
        } else if viewModel.orders.isEmpty {
          ContentUnavailableView(
            "No orders",
            systemImage: "shippingbox",
            description: Text("Pull to refresh.")
          )
        } else {
          List(viewModel.orders) { order in
            NavigationLink {
              OrderDetailsView(
                viewModel: OrderDetailsViewModel(
                  orderId: order.id,
                  service: viewModel.service,
                  order: order
                )
              )
            } label: {
              VStack(alignment: .leading, spacing: 6) {
                HStack {
                  Text("Order #\(order.id)")
                    .font(.headline)
                  Spacer()
                  Text(order.formattedTotal)
                    .fontWeight(.bold)
                }

                Text(order.customer.displayName)
                  .font(.subheadline)
                  .foregroundStyle(.secondary)

                HStack {
                  Text(order.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())

                  Text(order.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
              .padding(.vertical, 4)
            }
          }
        }
      }
      .navigationTitle("Orders")
      .task {
        await viewModel.loadOrders()
      }
      .refreshable {
        await viewModel.loadOrders()
      }
    }
  }
}
