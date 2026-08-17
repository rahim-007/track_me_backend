import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateGoalDto } from './create-goal.dto';

async function expectValid(payload: Partial<CreateGoalDto>) {
  const dto = plainToInstance(CreateGoalDto, payload);
  const errors = await validate(dto);
  expect(errors).toEqual([]);
}

async function expectInvalid(
  payload: Partial<CreateGoalDto>,
  property: string,
) {
  const dto = plainToInstance(CreateGoalDto, payload);
  const errors = await validate(dto);
  expect(errors.length).toBeGreaterThan(0);
  expect(errors.map((e) => e.property)).toContain(property);
}

const base = { name: 'Lose Weight', targetDate: '2026-12-31' };

describe('CreateGoalDto — type-aware target validation', () => {
  it('accepts fractional targets for measurement units', async () => {
    await expectValid({ ...base, target: 0.5, unit: 'kg' });
    await expectValid({ ...base, target: 1.25, unit: 'kg' });
    await expectValid({ ...base, target: 2.5, unit: 'km' });
    await expectValid({ ...base, target: 3, unit: 'L' });
    await expectValid({ ...base, target: 1.5, unit: 'hours' });
  });

  it('rejects fractional targets for count/currency units', async () => {
    await expectInvalid({ ...base, target: 2.5, unit: 'books' }, 'target');
    await expectInvalid({ ...base, target: 1.5, unit: 'tasks' }, 'target');
    await expectInvalid({ ...base, target: 2.25, unit: 'workouts' }, 'target');
    await expectInvalid({ ...base, target: 5000.5, unit: '₹' }, 'target');
  });

  it('accepts whole-number targets for count/currency units', async () => {
    await expectValid({ ...base, target: 10, unit: 'books' });
    await expectValid({ ...base, target: 5, unit: 'tasks' });
    await expectValid({ ...base, target: 2, unit: 'workouts' });
    await expectValid({ ...base, target: 50000, unit: '₹' });
  });

  it('accepts whole-number targets without a unit (legacy behavior)', async () => {
    await expectValid({ ...base, target: 5 });
    await expectValid(base); // no target at all
  });

  it('rejects unknown units', async () => {
    await expectInvalid({ ...base, target: 5, unit: 'widgets' }, 'unit');
  });

  it('rejects negative targets', async () => {
    await expectInvalid({ ...base, target: -5, unit: 'kg' }, 'target');
  });
});
