"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const schedule_1 = require("@nestjs/schedule");
const database_module_1 = require("./database/database.module");
const health_module_1 = require("./health/health.module");
const auth_module_1 = require("./auth/auth.module");
const users_module_1 = require("./users/users.module");
const accounts_module_1 = require("./accounts/accounts.module");
const categories_module_1 = require("./categories/categories.module");
const transactions_module_1 = require("./transactions/transactions.module");
const sync_module_1 = require("./sync/sync.module");
const budget_periods_module_1 = require("./budget-periods/budget-periods.module");
const budgets_module_1 = require("./budgets/budgets.module");
const reports_module_1 = require("./reports/reports.module");
const recurring_rules_module_1 = require("./recurring-rules/recurring-rules.module");
const goals_module_1 = require("./goals/goals.module");
const reminders_module_1 = require("./reminders/reminders.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            schedule_1.ScheduleModule.forRoot(),
            database_module_1.DatabaseModule,
            users_module_1.UsersModule,
            auth_module_1.AuthModule,
            accounts_module_1.AccountsModule,
            categories_module_1.CategoriesModule,
            transactions_module_1.TransactionsModule,
            sync_module_1.SyncModule,
            budget_periods_module_1.BudgetPeriodsModule,
            budgets_module_1.BudgetsModule,
            reports_module_1.ReportsModule,
            recurring_rules_module_1.RecurringRulesModule,
            goals_module_1.GoalsModule,
            reminders_module_1.RemindersModule,
            health_module_1.HealthModule,
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map