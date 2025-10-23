import { format } from 'date-fns';

interface Message {
  id: string;
  content: string;
  insertedAt: string;
  user: {
    id: string;
    username: string;
    firstName: string;
    lastName: string;
  };
}

interface MessageItemProps {
  message: Message;
}

export const MessageItem = ({ message }: MessageItemProps) => {
  const formatTime = (dateString: string) => {
    try {
      return format(new Date(dateString), 'HH:mm');
    } catch {
      return 'Invalid time';
    }
  };

  return (
    <div className="flex space-x-3">
      <div className="flex-shrink-0">
        <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center text-white text-sm font-medium">
          {message.user.firstName.charAt(0).toUpperCase()}
        </div>
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center space-x-2 mb-1">
          <span className="text-sm font-medium text-gray-900">
            {message.user.firstName} {message.user.lastName}
          </span>
          <span className="text-xs text-gray-500">
            {formatTime(message.insertedAt)}
          </span>
        </div>
        <div className="text-sm text-gray-700 break-words">
          {message.content}
        </div>
      </div>
    </div>
  );
};
