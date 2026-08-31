import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { DeleteAccountController } from './delete-account.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController, DeleteAccountController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
