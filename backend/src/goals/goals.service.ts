import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { AccountsRepository } from '../accounts/accounts.repository';
import { GoalsRepository } from './goals.repository';
import { CreateGoalDto } from './dto/create-goal.dto';
import { UpdateGoalDto } from './dto/update-goal.dto';

@Injectable()
export class GoalsService {
  constructor(
    private readonly goalsRepository: GoalsRepository,
    private readonly accountsRepository: AccountsRepository,
  ) {}

  async create(userId: string, dto: CreateGoalDto) {
    if (dto.accountId) {
      const account = await this.accountsRepository.findByIdAndUser(
        dto.accountId,
        userId,
      );
      if (!account) {
        throw new BadRequestException('Akun tidak ditemukan');
      }
    }
    const goal = await this.goalsRepository.create(userId, dto);
    return this.withProgress(goal);
  }

  async findAll(userId: string) {
    const goals = await this.goalsRepository.findAllByUser(userId);
    return Promise.all(goals.map((g) => this.withProgress(g)));
  }

  async findOne(userId: string, id: string) {
    const goal = await this.goalsRepository.findByIdAndUser(id, userId);
    if (!goal) {
      throw new NotFoundException('Goal tidak ditemukan');
    }
    return this.withProgress(goal);
  }

  async update(userId: string, id: string, dto: UpdateGoalDto) {
    const goal = await this.goalsRepository.update(id, userId, dto);
    if (!goal) {
      throw new NotFoundException('Goal tidak ditemukan');
    }
    return this.withProgress(goal);
  }

  async remove(userId: string, id: string) {
    const deleted = await this.goalsRepository.softDelete(id, userId);
    if (!deleted) {
      throw new NotFoundException('Goal tidak ditemukan');
    }
  }

  private async withProgress<T extends { id: string; target_amount: string }>(
    goal: T,
  ) {
    const currentAmount = await this.goalsRepository.getCurrentAmount(
      goal.id,
    );
    const target = Number(goal.target_amount);
    return {
      ...goal,
      currentAmount,
      percentage: target > 0 ? Math.round((currentAmount / target) * 100) : 0,
    };
  }
}
