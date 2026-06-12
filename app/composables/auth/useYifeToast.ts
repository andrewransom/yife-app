import { useToast } from '#imports';

type ToastTone = 'success' | 'error' | 'info' | 'warning';

export function useYifeToast() {
  const toast = useToast();

  const notify = (tone: ToastTone, title: string, description?: string) => {
    toast.add({
      color: tone,
      title,
      description,
    });
  };

  return {
    success: (title: string, description?: string) => notify('success', title, description),
    error: (title: string, description?: string) => notify('error', title, description),
    info: (title: string, description?: string) => notify('info', title, description),
    warning: (title: string, description?: string) => notify('warning', title, description),
  };
}
