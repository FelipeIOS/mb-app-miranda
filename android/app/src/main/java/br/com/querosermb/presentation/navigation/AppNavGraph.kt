package br.com.querosermb.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import br.com.querosermb.domain.model.Exchange
import br.com.querosermb.presentation.exchangedetail.ExchangeDetailScreen
import br.com.querosermb.presentation.exchangelist.ExchangeListScreen

private object Routes {
    const val EXCHANGE_LIST = "exchangeList"
    const val EXCHANGE_DETAIL = "detail/{id}/{name}/{logo}/{slug}"

    fun detailRoute(exchange: Exchange): String {
        val encodedName = java.net.URLEncoder.encode(exchange.name, "UTF-8")
        val encodedLogo = java.net.URLEncoder.encode(exchange.logo, "UTF-8")
        val encodedSlug = java.net.URLEncoder.encode(exchange.slug, "UTF-8")
        return "detail/${exchange.id}/$encodedName/$encodedLogo/$encodedSlug"
    }
}

@Composable
fun AppNavGraph() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Routes.EXCHANGE_LIST) {
        composable(Routes.EXCHANGE_LIST) {
            ExchangeListScreen(
                onItemClick = { exchange ->
                    navController.navigate(Routes.detailRoute(exchange))
                }
            )
        }

        composable(
            route = Routes.EXCHANGE_DETAIL,
            arguments = listOf(
                navArgument("id") { type = NavType.IntType },
                navArgument("name") { type = NavType.StringType },
                navArgument("logo") { type = NavType.StringType },
                navArgument("slug") { type = NavType.StringType }
            )
        ) { backStackEntry ->
            val id = backStackEntry.arguments?.getInt("id") ?: return@composable
            val name = backStackEntry.arguments?.getString("name")?.let {
                java.net.URLDecoder.decode(it, "UTF-8")
            } ?: return@composable
            val logo = backStackEntry.arguments?.getString("logo")?.let {
                java.net.URLDecoder.decode(it, "UTF-8")
            } ?: return@composable
            val slug = backStackEntry.arguments?.getString("slug")?.let {
                java.net.URLDecoder.decode(it, "UTF-8")
            } ?: return@composable

            val exchange = Exchange(
                id = id, name = name, logo = logo, slug = slug,
                description = null, websiteURL = null, makerFee = null,
                takerFee = null, dateLaunched = null, spotVolumeUSD = null
            )

            ExchangeDetailScreen(
                exchange = exchange,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
