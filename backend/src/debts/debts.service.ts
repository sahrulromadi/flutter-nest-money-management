import { Injectable, NotFoundException } from '@nestjs/common';
import { DebtsRepository } from './debts.repository';
import { CreateDebtDto } from './dto/create-debt.dto';
import { UpdateDebtDto } from './dto/update-debt.dto';

@Injectable()
export class DebtsService {
  constructor(private readonly debtsRepository: DebtsRepository) {}

  async create(userId: string, dto: CreateDebtDto) {
    const debt = await this.debtsRepository.create(userId, dto);
    return this.withProgress(debt);
  }

  async findAll(userId: string) {
    const debts = await this.debtsRepository.findAllByUser(userId);
    return Promise.all(debts.map((d) => this.withProgress(d)));
  }

  async findOne(userId: string, id: string) {
    const debt = await this.debtsRepository.findByIdAndUser(id, userId);
    if (!debt) {
      throw new NotFoundException('Utang/piutang tidak ditemukan');
    }
    return this.withProgress(debt);
  }

  async update(userId: string, id: string, dto: UpdateDebtDto) {
    const debt = await this.debtsRepository.update(id, userId, dto);
    if (!debt) {
      throw new NotFoundException('Utang/piutang tidak ditemukan');
    }
    return this.withProgress(debt);
  }

  async remove(userId: string, id: string) {
    const deleted = await this.debtsRepository.softDelete(id, userId);
    if (!deleted) {
      throw new NotFoundException('Utang/piutang tidak ditemukan');
    }
  }

  private async withProgress<T extends { id: string; amount: string }>(
    debt: T,
  ) {
    const paidAmount = await this.debtsRepository.getCurrentAmount(debt.id);
    const amount = Number(debt.amount);
    return {
      ...debt,
      paidAmount,
      percentage: amount > 0 ? Math.round((paidAmount / amount) * 100) : 0,
      lunas: paidAmount >= amount,
    };
  }
}
