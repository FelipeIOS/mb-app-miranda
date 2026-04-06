package br.com.querosermb

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import br.com.querosermb.presentation.MainActivity
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@HiltAndroidTest
class ExchangeListScreenTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun init() {
        hiltRule.inject()
    }

    @Test
    fun exchangeListDisplaysAlphaExchange() {
        composeRule.onNodeWithText("Alpha Exchange").assertIsDisplayed()
    }

    @Test
    fun exchangeListDisplaysBetaExchange() {
        composeRule.onNodeWithText("Beta Exchange").assertIsDisplayed()
    }

    @Test
    fun tappingExchangeNavigatesToDetail() {
        composeRule.onNodeWithText("Alpha Exchange").performClick()
        // After navigation, the detail screen shows "ID: 1" — unique identifier
        composeRule.onNodeWithText("ID: 1").assertIsDisplayed()
    }
}
