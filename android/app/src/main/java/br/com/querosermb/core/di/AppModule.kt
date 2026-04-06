package br.com.querosermb.core.di

import br.com.querosermb.BuildConfig
import br.com.querosermb.core.cache.Clock
import br.com.querosermb.core.cache.ExchangeDetailCache
import br.com.querosermb.core.cache.ExchangeDetailCaching
import br.com.querosermb.core.cache.SystemClock
import br.com.querosermb.core.network.ApiService
import br.com.querosermb.data.remote.datasource.ExchangeRemoteDataSource
import br.com.querosermb.data.remote.datasource.ExchangeRemoteDataSourcing
import br.com.querosermb.data.repository.ExchangeRepositoryImpl
import br.com.querosermb.domain.repository.ExchangeRepository
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideGson(): Gson = GsonBuilder().create()

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val apiKeyInterceptor = Interceptor { chain ->
            val request = chain.request().newBuilder()
                .addHeader("X-CMC_PRO_API_KEY", BuildConfig.CMC_API_KEY)
                .addHeader("Accept", "application/json")
                .build()
            chain.proceed(request)
        }

        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
        }

        return OkHttpClient.Builder()
            .addInterceptor(apiKeyInterceptor)
            .addInterceptor(loggingInterceptor)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, gson: Gson): Retrofit =
        Retrofit.Builder()
            .baseUrl("https://pro-api.coinmarketcap.com")
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

    @Provides
    @Singleton
    fun provideApiService(retrofit: Retrofit): ApiService =
        retrofit.create(ApiService::class.java)
}

@Module
@InstallIn(SingletonComponent::class)
abstract class DataModule {

    @Binds
    @Singleton
    abstract fun bindExchangeRemoteDataSource(
        impl: ExchangeRemoteDataSource
    ): ExchangeRemoteDataSourcing

    @Binds
    @Singleton
    abstract fun bindExchangeRepository(
        impl: ExchangeRepositoryImpl
    ): ExchangeRepository

    @Binds
    @Singleton
    abstract fun bindExchangeDetailCache(
        impl: ExchangeDetailCache
    ): ExchangeDetailCaching

    @Binds
    @Singleton
    abstract fun bindClock(impl: SystemClock): Clock
}
