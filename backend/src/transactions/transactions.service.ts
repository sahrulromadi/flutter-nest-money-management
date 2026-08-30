import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AccountsRepository } from '../accounts/accounts.repository';
import { CategoriesRepository } from '../categories/categories.repository';
import { TransactionsRepository } from './transactions.repository';
import { CreateTransactionDto } from './dto/create-transaction.dto';
import { UpdateTransactionDto } from './dto/update-transaction.dto';
import { QueryTransactionsDto } from './dto/query-transactions.dto';

interface PgError {
  code?: string;
}

function isPgError(error: unknown): error is PgError {
  return typeof error === 'object' && error !== null && 'code' in error;
}

@Injectable()
export class TransactionsService {
  constructor(
    private readonly transactionsRepository: TransactionsRepository,
    private readonly accountsRepository: AccountsRepository,
    private readonly categoriesRepository: CategoriesRepository,
  ) {}

  async create(userId: string, dto: CreateTransactionDto) {
    await this.assertAccountOwned(userId, dto.accountId);
    if (dto.transferToAccountId) {
      await this.assertAccountOwned(userId, dto.transferToAccountId);
    }
    if (dto.categoryId) {
      const category = await this.categoriesRepository.findByIdAndUser(
        dto.categoryId,
        userId,
      );
      if (!category) {
        throw new BadRequestException('Kategori tidak ditemukan');
      }
      if (category.type !== dto.type) {
        throw new BadRequestException(
          'Tipe kategori harus sama dengan tipe transaksi',
        );
      }
    }

    try {
      return await this.transactionsRepository.create(userId, dto);
    } catch (error) {
      throw this.translateDbError(error);
    }
  }

  async findAll(userId: string, filter: QueryTransactionsDto) {
    return this.transactionsRepository.findAllByUser(userId, filter);
  }

  async findOne(userId: string, id: string) {
    const transaction = await this.transactionsRepository.findByIdAndUser(
      id,
      userId,
    );
    if (!transaction) {
      throw new NotFoundException('Transaksi tidak ditemukan');
    }
    return transaction;
  }

  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    if (dto.categoryId) {
      const category = await this.categoriesRepository.findByIdAndUser(
        dto.categoryId,
        userId,
      );
      if (!category) {
        throw new BadRequestException('Kategori tidak ditemukan');
      }
    }

    try {
      const transaction = await this.transactionsRepository.update(
        id,
        userId,
        dto,
      );
      if (!transaction) {
        throw new NotFoundException('Transaksi tidak ditemukan');
      }
      return transaction;
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw this.translateDbError(error);
    }
  }

  async remove(userId: string, id: string) {
    const deleted = await this.transactionsRepository.softDelete(id, userId);
    if (!deleted) {
      throw new NotFoundException('Transaksi tidak ditemukan');
    }
  }

  private async assertAccountOwned(userId: string, accountId: string) {
    const account = await this.accountsRepository.findByIdAndUser(
      accountId,
      userId,
    );
    if (!account) {
      throw new BadRequestException('Akun tidak ditemukan');
    }
  }

  private translateDbError(error: unknown) {
    if (isPgError(error) && error.code === '23514') {
      return new BadRequestException(
        'Data transaksi gak valid (cek tipe/akun tujuan transfer)',
      );
    }
    return error;
  }
}
