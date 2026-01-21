import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = StoreKitService.shared
    @State private var purchaseInProgress = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primaryText)
                }
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.accent)
                        
                        Text("Go Premium")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Text("Unlock unlimited plan generations")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 16) {
                        BenefitRow(icon: "infinity", text: "Unlimited generations")
                        BenefitRow(icon: "bolt.fill", text: "Priority AI processing")
                        BenefitRow(icon: "heart.fill", text: "Support indie development")
                    }
                    .padding(.horizontal)
                    
                    // Products
                    VStack(spacing: 12) {
                        ForEach(store.products.sorted { $0.price < $1.price }, id: \.id) { product in
                            ProductCard(product: product, isLoading: purchaseInProgress) {
                                await purchase(product)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Restore
                    Button("Restore Purchases") {
                        Task { await store.restorePurchases() }
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.top, 8)
                    
                    // Terms
                    Text("Payment will be charged to your Apple ID. Subscriptions auto-renew unless cancelled 24h before expiry.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }
    
    private func purchase(_ product: Product) async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
            let success = try await store.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Subviews

private struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.accent)
                .frame(width: 32)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
        }
    }
}

private struct ProductCard: View {
    let product: Product
    let isLoading: Bool
    let action: () async -> Void
    
    private var isLifetime: Bool {
        product.id == StoreKitService.lifetimeID
    }
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isLifetime ? "Lifetime" : "Monthly")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(product.displayPrice + (isLifetime ? " once" : "/month"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                } else {
                    Text("Subscribe")
                        .font(DesignSystem.Typography.button)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.accent)
                        .cornerRadius(DesignSystem.cornerRadius)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
                    .stroke(isLifetime ? DesignSystem.Colors.accent : DesignSystem.Colors.border, lineWidth: isLifetime ? 2 : 1)
            )
        }
        .disabled(isLoading)
    }
}
