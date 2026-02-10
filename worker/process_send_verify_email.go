package worker

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log/slog"

	"github.com/hibiken/asynq"
)

func (processor *RedisTaskProcessor) ProcessTaskSendVerifyEmail(ctx context.Context, task *asynq.Task) error {
	var payload PayloadSendVerifyEmail
	if err := json.Unmarshal(task.Payload(), &payload); err != nil {
		slog.ErrorContext(
			ctx,
			"failed to unmarshal verify email task payload",
			"error", err, // 错误详情
			"task_type", task.Type(),
			"task_id", task.ResultWriter().TaskID(),
		)
		return fmt.Errorf("failed to unmarshal payload: %w", asynq.SkipRetry)
	}

	user, err := processor.store.GetUser(ctx, payload.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user doesn't exist: %w", asynq.SkipRetry)
		}
		return fmt.Errorf("failed to get user: %w", err)
	}

	subject := "Welcome to Simple Bank"
	content := fmt.Sprintf("Hello %s, thank you for registering!", user.FullName)
	to := []string{user.Email}

	err = processor.mailer.SendEmail(subject, content, to, nil, nil, nil)
	logger := slog.With(
		slog.String("username", user.Username),
		slog.String("email", user.Email),
	)

	if err != nil {
		logger.Error("failed to send verify email", slog.String("error", err.Error()))
		return fmt.Errorf("failed to send verify email: %w", err)
	}

	logger.Info("success to send verify email")
	return nil
}
