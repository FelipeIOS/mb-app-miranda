package br.com.querosermb

import br.com.querosermb.core.cache.Clock
import br.com.querosermb.core.cache.ExchangeDetailCache
import br.com.querosermb.core.cache.ExchangeDetailCaching
import br.com.querosermb.core.cache.SystemClock
import br.com.querosermb.core.di.DataModule
import br.com.querosermb.core.di.NetworkModule
import br.com.querosermb.domain.repository.ExchangeRepository
import dagger.Binds
import dagger.Module
import dagger.Provides
import dagger.hilt.components.SingletonComponent
import dagger.hilt.testing.TestInstallIn
import javax.inject.Singleton

@Module
@TestInstallIn(components = [SingletonComponent::class], replaces = [DataModule::class])
abstract class TestDataModule {

    @Binds
    @Singleton
    abstract fun bindExchangeRepository(fake: FakeExchangeRepository): ExchangeRepository

    @Binds
    @Singleton
    abstract fun bindExchangeDetailCache(impl: ExchangeDetailCache): ExchangeDetailCaching

    @Binds
    @Singleton
    abstract fun bindClock(impl: SystemClock): Clock
}

@Module
@TestInstallIn(components = [SingletonComponent::class], replaces = [NetworkModule::class])
object TestNetworkModule {
    // No network in tests — FakeExchangeRepository handles data
}
