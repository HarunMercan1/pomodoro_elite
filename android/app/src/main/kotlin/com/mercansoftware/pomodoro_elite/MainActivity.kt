package com.mercansoftware.pomodoro_elite

import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.QueryPurchasesParams
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val OWNERSHIP_CHANNEL =
            "com.mercansoftware.pomodoro_elite/play_store_ownership"
        private const val GET_OWNED_PRODUCTS = "getOwnedInAppProductIds"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OWNERSHIP_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != GET_OWNED_PRODUCTS) {
                result.notImplemented()
                return@setMethodCallHandler
            }

            queryOwnedInAppProducts(result)
        }
    }

    private fun queryOwnedInAppProducts(result: MethodChannel.Result) {
        val billingClient = BillingClient.newBuilder(applicationContext)
            .setListener { _, _ ->
                // Purchases are performed by RevenueCat. This client is
                // intentionally read-only and only verifies active ownership.
            }
            .enablePendingPurchases(
                PendingPurchasesParams.newBuilder()
                    .enableOneTimeProducts()
                    .build(),
            )
            .build()

        var completed = false

        fun finishWithError(code: String, billingResult: BillingResult) {
            if (completed) return
            completed = true
            billingClient.endConnection()
            result.error(
                code,
                billingResult.debugMessage,
                billingResult.responseCode,
            )
        }

        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(setupResult: BillingResult) {
                if (setupResult.responseCode != BillingClient.BillingResponseCode.OK) {
                    finishWithError("PLAY_BILLING_SETUP_FAILED", setupResult)
                    return
                }

                val params = QueryPurchasesParams.newBuilder()
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build()

                billingClient.queryPurchasesAsync(params) { queryResult, purchases ->
                    if (queryResult.responseCode != BillingClient.BillingResponseCode.OK) {
                        finishWithError("PLAY_BILLING_QUERY_FAILED", queryResult)
                        return@queryPurchasesAsync
                    }

                    if (completed) return@queryPurchasesAsync
                    completed = true

                    val ownedProductIds = purchases
                        .asSequence()
                        .filter { it.purchaseState == Purchase.PurchaseState.PURCHASED }
                        .flatMap { it.products.asSequence() }
                        .distinct()
                        .toList()

                    billingClient.endConnection()
                    result.success(ownedProductIds)
                }
            }

            override fun onBillingServiceDisconnected() {
                if (completed) return
                completed = true
                billingClient.endConnection()
                result.error(
                    "PLAY_BILLING_DISCONNECTED",
                    "Google Play Billing service disconnected.",
                    null,
                )
            }
        })
    }
}
