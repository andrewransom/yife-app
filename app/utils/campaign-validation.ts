import { z } from 'zod';

const optionalDateSchema = z
  .string()
  .trim()
  .optional()
  .transform((value) => (value ? value : undefined));

export const createCampaignSchema = z
  .object({
    name: z.string().trim().min(1, 'Campaign name is required.'),
    description: z
      .string()
      .trim()
      .optional()
      .transform((value) => (value ? value : undefined)),
    startDate: z.string().trim().min(1, 'Start date is required.'),
    endDate: optionalDateSchema,
  })
  .refine((value) => !value.endDate || value.endDate >= value.startDate, {
    message: 'End date cannot be before start date.',
    path: ['endDate'],
  });

export type CreateCampaignFormInput = z.input<typeof createCampaignSchema>;
export type CreateCampaignFormOutput = z.output<typeof createCampaignSchema>;
