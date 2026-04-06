package br.com.querosermb.presentation.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import br.com.querosermb.presentation.exchangedetail.ExchangeDetailScreen
import br.com.querosermb.presentation.exchangelist.ExchangeListScreen

private object Routes {
    const val EXCHANGE_LIST = "exchangeList"
    const val EXCHANGE_DETAIL = "detail/{id}"

    fun detailRoute(id: Int) = "detail/$id"
}

@Composable
fun AppNavGraph() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Routes.EXCHANGE_LIST) {
        composable(Routes.EXCHANGE_LIST) {
            ExchangeListScreen(
                onItemClick = { exchange ->
                    navController.navigate(Routes.detailRoute(exchange.id))
                }
            )
        }

        composable(
            route = Routes.EXCHANGE_DETAIL,
            arguments = listOf(
                navArgument("id") { type = NavType.IntType }
            )
        ) { backStackEntry ->
            val id = backStackEntry.arguments?.getInt("id") ?: return@composable

            ExchangeDetailScreen(
                exchangeId = id,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
