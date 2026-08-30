import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CategoriesRepository } from './categories.repository';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
  constructor(private readonly categoriesRepository: CategoriesRepository) {}

  async create(userId: string, dto: CreateCategoryDto) {
    if (dto.parentId) {
      const parent = await this.categoriesRepository.findByIdAndUser(
        dto.parentId,
        userId,
      );
      if (!parent) {
        throw new BadRequestException('Kategori induk tidak ditemukan');
      }
      if (parent.type !== dto.type) {
        throw new BadRequestException(
          'Tipe subkategori harus sama dengan kategori induk',
        );
      }
    }
    return this.categoriesRepository.create(userId, dto);
  }

  findAll(userId: string, type?: string) {
    return this.categoriesRepository.findAllByUser(userId, type);
  }

  async findOne(userId: string, id: string) {
    const category = await this.categoriesRepository.findByIdAndUser(
      id,
      userId,
    );
    if (!category) {
      throw new NotFoundException('Kategori tidak ditemukan');
    }
    return category;
  }

  async update(userId: string, id: string, dto: UpdateCategoryDto) {
    const category = await this.categoriesRepository.update(id, userId, dto);
    if (!category) {
      throw new NotFoundException('Kategori tidak ditemukan');
    }
    return category;
  }

  async remove(userId: string, id: string) {
    const deleted = await this.categoriesRepository.softDelete(id, userId);
    if (!deleted) {
      throw new NotFoundException('Kategori tidak ditemukan');
    }
  }
}
