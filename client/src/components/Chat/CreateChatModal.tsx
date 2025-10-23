import { useState } from 'react';
import { useMutation, useQuery } from 'urql';
import { CREATE_DIRECT_CHAT_MUTATION, CREATE_GROUP_CHAT_MUTATION } from '../../lib/mutations';
import { USERS_QUERY } from '../../lib/queries';

interface CreateChatModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CreateChatModal = ({ isOpen, onClose }: CreateChatModalProps) => {
  const [chatType, setChatType] = useState<'direct' | 'group'>('direct');
  const [groupName, setGroupName] = useState('');
  const [selectedUsers, setSelectedUsers] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [, createDirectChat] = useMutation(CREATE_DIRECT_CHAT_MUTATION);
  const [, createGroupChat] = useMutation(CREATE_GROUP_CHAT_MUTATION);
  const [{ data: usersData }] = useQuery({ 
    query: USERS_QUERY, 
    variables: { excludeSelf: true } 
  });

  const users = usersData?.users || [];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      if (chatType === 'direct') {
        if (selectedUsers.length !== 1) {
          alert('Please select exactly one user for direct message');
          return;
        }
        await createDirectChat({ userId: selectedUsers[0] });
      } else {
        if (!groupName.trim()) {
          alert('Please enter a group name');
          return;
        }
        if (selectedUsers.length === 0) {
          alert('Please select at least one user for the group');
          return;
        }
        await createGroupChat({ 
          name: groupName.trim(), 
          participantIds: selectedUsers 
        });
      }
      
      onClose();
      setGroupName('');
      setSelectedUsers([]);
    } catch (error) {
      console.error('Error creating chat:', error);
      alert('Failed to create chat. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const toggleUser = (userId: string) => {
    if (chatType === 'direct') {
      setSelectedUsers([userId]);
    } else {
      setSelectedUsers(prev => 
        prev.includes(userId) 
          ? prev.filter(id => id !== userId)
          : [...prev, userId]
      );
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
        <h2 className="text-xl font-bold mb-4">Create Chat</h2>
        
        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Chat Type
            </label>
            <div className="flex space-x-4">
              <label className="flex items-center">
                <input
                  type="radio"
                  value="direct"
                  checked={chatType === 'direct'}
                  onChange={(e) => setChatType(e.target.value as 'direct')}
                  className="mr-2"
                />
                Direct Message
              </label>
              <label className="flex items-center">
                <input
                  type="radio"
                  value="group"
                  checked={chatType === 'group'}
                  onChange={(e) => setChatType(e.target.value as 'group')}
                  className="mr-2"
                />
                Group Chat
              </label>
            </div>
          </div>

          {chatType === 'group' && (
            <div className="mb-4">
              <label htmlFor="groupName" className="block text-sm font-medium text-gray-700 mb-2">
                Group Name
              </label>
              <input
                type="text"
                id="groupName"
                value={groupName}
                onChange={(e) => setGroupName(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                placeholder="Enter group name"
              />
            </div>
          )}

          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Select Users
            </label>
            <div className="max-h-40 overflow-y-auto border border-gray-300 rounded-md">
              {users.map((user: any) => (
                <label key={user.id} className="flex items-center p-2 hover:bg-gray-50">
                  <input
                    type="checkbox"
                    checked={selectedUsers.includes(user.id)}
                    onChange={() => toggleUser(user.id)}
                    className="mr-2"
                  />
                  <span className="text-sm">
                    {user.firstName} {user.lastName} (@{user.username})
                  </span>
                </label>
              ))}
            </div>
          </div>

          <div className="flex justify-end space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-md disabled:opacity-50"
            >
              {isSubmitting ? 'Creating...' : 'Create Chat'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
