package br.com.querosermb

import br.com.querosermb.core.network.ApiService
import br.com.querosermb.core.network.NetworkError
import br.com.querosermb.data.remote.datasource.ExchangeRemoteDataSource
import br.com.querosermb.data.remote.dto.ExchangeMapResponse
import com.google.gson.JsonParseException
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertTrue
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response
import java.io.IOException

class ExchangeRemoteDataSourceTest {

    private val apiService = mockk<ApiService>()
    private val dataSource = ExchangeRemoteDataSource(apiService)

    @Test
    fun `safeCall wraps HttpException as ServerError`() = runTest {
        val httpException = HttpException(Response.error<ExchangeMapResponse>(503, okhttp3.ResponseBody.create(null, "")))
        coEvery { apiService.getExchangeMap(any(), any()) } throws httpException

        try {
            dataSource.fetchExchangeMap(1, 40)
        } catch (e: NetworkError.ServerError) {
            assertTrue(e.statusCode == 503)
            return@runTest
        }
        error("Expected NetworkError.ServerError")
    }

    @Test
    fun `safeCall wraps JsonParseException as DecodingError`() = runTest {
        coEvery { apiService.getExchangeMap(any(), any()) } throws JsonParseException("bad json")

        try {
            dataSource.fetchExchangeMap(1, 40)
        } catch (e: NetworkError.DecodingError) {
            assertTrue(e.cause is JsonParseException)
            return@runTest
        }
        error("Expected NetworkError.DecodingError")
    }

    @Test
    fun `safeCall wraps IOException as NoConnection`() = runTest {
        coEvery { apiService.getExchangeMap(any(), any()) } throws IOException("timeout")

        try {
            dataSource.fetchExchangeMap(1, 40)
        } catch (e: NetworkError) {
            assertTrue(e is NetworkError.NoConnection)
            return@runTest
        }
        error("Expected NetworkError.NoConnection")
    }

    @Test
    fun `safeCall wraps unexpected exception as Unknown`() = runTest {
        coEvery { apiService.getExchangeMap(any(), any()) } throws IllegalStateException("unexpected")

        try {
            dataSource.fetchExchangeMap(1, 40)
        } catch (e: NetworkError.Unknown) {
            assertTrue(e.cause is IllegalStateException)
            return@runTest
        }
        error("Expected NetworkError.Unknown")
    }
}
