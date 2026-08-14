import {
  Controller, Get, Post, Delete, Body, Param, Request, UseGuards
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ExtraIncomeService } from './extra-income.service';
import { CreateExtraIncomeDto } from './dto/create-extra-income.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Extra Income')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
@Controller('extra-income')
export class ExtraIncomeController {
  constructor(private readonly extraIncomeService: ExtraIncomeService) {}

  @Get()
  @ApiOperation({ summary: 'Get all extra income entries' })
  findAll(@Request() req: any) {
    return this.extraIncomeService.findAll(req.user.id);
  }

  @Get('total')
  @ApiOperation({ summary: 'Get total extra income amount' })
  getTotal(@Request() req: any) {
    return this.extraIncomeService.getTotal(req.user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Add a new extra income entry' })
  create(@Request() req: any, @Body() dto: CreateExtraIncomeDto) {
    return this.extraIncomeService.create(req.user.id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete an extra income entry' })
  remove(@Request() req: any, @Param('id') id: string) {
    return this.extraIncomeService.remove(req.user.id, id);
  }
}
