import { Injectable, NotFoundException } from '@nestjs/common';
import { AccountsRepository } from './accounts.repository';
import { CreateAccountDto } from './dto/create-account.dto';
import { UpdateAccountDto } from './dto/update-account.dto';

@Injectable()
export class AccountsService {
  constructor(private readonly accountsRepository: AccountsRepository) {}

  async create(userId: string, dto: CreateAccountDto) {
    const account = await this.accountsRepository.create(userId, dto);
    return this.withBalance(account);
  }

  async findAll(userId: string) {
    const accounts = await this.accountsRepository.findAllByUser(userId);
    return Promise.all(accounts.map((a) => this.withBalance(a)));
  }

  async findOne(userId: string, id: string) {
    const account = await this.accountsRepository.findByIdAndUser(id, userId);
    if (!account) {
      throw new NotFoundException('Akun tidak ditemukan');
    }
    return this.withBalance(account);
  }

  async update(userId: string, id: string, dto: UpdateAccountDto) {
    const account = await this.accountsRepository.update(id, userId, dto);
    if (!account) {
      throw new NotFoundException('Akun tidak ditemukan');
    }
    return this.withBalance(account);
  }

  async remove(userId: string, id: string) {
    const deleted = await this.accountsRepository.softDelete(id, userId);
    if (!deleted) {
      throw new NotFoundException('Akun tidak ditemukan');
    }
  }

  private async withBalance<T extends { id: string }>(account: T) {
    const balance = await this.accountsRepository.getBalance(account.id);
    return { ...account, balance };
  }
}
