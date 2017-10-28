describe SignUpSheetController do
  let(:assignment) { build(:assignment, id: 1, instructor_id: 6, due_dates: [due_date], microtask: true, staggered_deadline: true) }
  let(:instructor) { build(:instructor, id: 6) }
  let(:student) { build(:student, id: 8) }
  let(:participant) { build(:participant, id: 1, user_id: 6, assignment: assignment) }
  let(:topic) { build(:topic, id: 1, topic_name: 'new topic', micropayment: 0, category: 'test',topic_identifier: '1', micropayment: 0, description: 'test', link: 'test') }
  let(:signed_up_team) { build(:signed_up_team, team: team, topic: topic) }
  let(:signed_up_team2) { build(:signed_up_team, team_id: 2, is_waitlisted: true) }
  let(:team) { build(:assignment_team, id: 1, assignment: assignment) }
  let(:due_date) { build(:assignment_due_date, deadline_type_id: 1) }
  let(:due_date2) { build(:assignment_due_date, deadline_type_id: 2) }
  let(:bid) { Bid.new(topic_id: 1, priority: 1) }
  let(:team_user) { build(:team_user) }
  before(:each) do
    allow(Assignment).to receive(:find).with('1').and_return(assignment)
    allow(Assignment).to receive(:find).with(1).and_return(assignment)
    stub_current_user(instructor, instructor.role.name, instructor.role)
    allow(SignUpTopic).to receive(:find).with('1').and_return(topic)
    allow(Participant).to receive(:find_by).with(id: '1').and_return(participant)
    allow(AssignmentParticipant).to receive(:find).with('1').and_return(participant)
    allow(AssignmentParticipant).to receive(:find).with(1).and_return(participant)
    allow(AssignmentParticipant).to receive(:find_by).with(user_id: student.id, parent_id: 1).and_return(participant)
    allow(participant).to receive(:team).and_return(team)
   allow(Team).to receive(:find).with('1').and_return(team)
    allow(TeamsUser).to receive(:find_by).with(team_id: 1).and_return(team_user)
    allow(team_user).to receive(:user).and_return(student)
  end

  describe '#new' do
    it 'builds a new sign up topic and renders sign_up_sheet#new page' do
      get :new,  id:  1.to_s
      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
   let(:params) { {id: 1, topic: {}}}
    context 'when topic cannot be found' do
      context 'when new topic can be saved successfully' do
        it 'sets up a new topic and redirects to assignment#edit page' do
          session[:user] = participant
          allow(SignUpTopic).to receive_message_chain(:where, :first).and_return(nil)
          allow_any_instance_of(SignUpTopic).to receive(:save).and_return(true)
          post :create, params
          expect(response).to redirect_to(edit_assignment_path(1.to_s) + "#tabs-5")
        end
      end

      context 'when new topic cannot be saved successfully' do
        it 'sets up a new topic and renders sign_up_sheet#new page' do
          allow(SignUpTopic).to receive_message_chain(:where, :first).and_return(nil)
          allow_any_instance_of(SignUpTopic).to receive(:save).and_return(false)
          post :create, params
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when topic can be found' do
      it 'updates the existing topic and redirects to sign_up_sheet#add_signup_topics_staggered page' do
        allow(SignUpTopic).to receive_message_chain(:where, :first).and_return(topic)
        post :create, params
        expect(response).to  redirect_to action: 'add_signup_topics_staggered', id: 1
      end
    end
  end




  describe '#destroy' do
    let(:params) { {id: 1, assignment_id: 1} }
    context 'when topic can be found' do
      it 'redirects to assignment#edit page' do
        session[:user] = participant
        post :destroy, params
        expect(response).to redirect_to(edit_assignment_path(1.to_s) + "#tabs-5")
      end
    end

    context 'when topic cannot be found' do
      it 'shows an error flash message and redirects to assignment#edit page' do
        allow(SignUpTopic).to receive(:find).with('1').and_return(nil)
        get :destroy, params
        expect(flash[:error]).to eq("The topic could not be deleted.")
        expect(response).to redirect_to(edit_assignment_path(1.to_s) + "#tabs-5")
      end
    end
  end

  describe '#edit' do
    it 'renders sign_up_sheet#edit page' do
      get :edit, id: 1
      expect(response).to render_template(:edit)
    end
  end

  describe '#update' do
    let(:params) { {id: 1, assignment_id: 1, topic: {}} }
    context 'when topic cannot be found' do
      it 'shows an error flash message and redirects to assignment#edit page' do
        allow(SignUpTopic).to receive(:find).with('1').and_return(nil)
        post :update, params
        expect(flash[:error]).to eq("The topic could not be updated.")
        expect(response).to redirect_to(edit_assignment_path(1.to_s) + "#tabs-5")
      end
    end

    context 'when topic can be found' do
      it 'updates current topic and redirects to assignment#edit page' do
        session[:user] = participant
        post :update, params
        expect(response).to redirect_to(edit_assignment_path(1.to_s) + "#tabs-5")
      end
    end
  end

  describe '#list' do
    context 'when current assignment is intelligent assignment and has submission duedate (deadline_type_id 1)' do
      it 'renders sign_up_sheet#intelligent_topic_selection page' do
        allow(assignment).to receive(:is_intelligent).and_return(true)
        get :list, id: 1
        expect(response).to render_template(:intelligent_topic_selection)
      end
    end

    context 'when current assignment is not intelligent assignment and has submission duedate (deadline_type_id 1)' do
      it 'renders sign_up_sheet#list page' do
        allow(assignment).to receive(:is_intelligent).and_return(false)
        get :list, id: 1
        expect(response).to render_template(:list)
      end
    end
  end

  describe '#sign_up' do
	let(:session) { {user: student } }
	let(:params) { {id: 1} }
    context 'when SignUpSheet.signup_team method return nil' do
      it 'shows an error flash message and redirects to sign_up_sheet#list page' do
        allow(SignUpSheet).to receive(:signup_team).with(any_args).and_return(nil)
        get :sign_up, params, session 
        expect(flash.now[:error]).to eq("You've already signed up for a topic!")
	expect(response).to redirect_to action: 'list', id: 1
      end
    end
  end

  describe '#signup_as_instructor_action' do
   let(:params) { {username: '1', assignment_id: 1} }
    context 'when user cannot be found' do
      it 'shows an flash error message and redirects to assignment#edit page' do
        allow(User).to receive(:find_by).with(any_args).and_return(nil)
        post :signup_as_instructor_action, params
        expect(flash.now[:error]).to eq("That student does not exist!")
        expect(response).to redirect_to controller: 'assignments', action: 'edit', id: params[:assignment_id]
      end
    end

    context 'when user can be found' do
      context 'when an assignment_participant can be found' do
        context 'when creating team related objects successfully' do
          it 'shows a flash success message and redirects to assignment#edit page' do
            allow(User).to receive(:find_by).with(any_args).and_return(student)
            allow(AssignmentParticipant).to receive(:exists?).with(any_args).and_return(true)
            allow(SignUpSheet).to receive(:signup_team).with(any_args).and_return(signed_up_team)
            post :signup_as_instructor_action, params
            expect(flash.now[:success]).to eq("You have successfully signed up the student for the topic!")
            expect(response).to redirect_to controller: 'assignments', action: 'edit', id: params[:assignment_id]
          end
        end

        context 'when creating team related objects unsuccessfully' do
          it 'shows a flash error message and redirects to assignment#edit page' do
            allow(User).to receive(:find_by).with(any_args).and_return(student)
            allow(AssignmentParticipant).to receive(:exists?).with(any_args).and_return(true)
            allow(SignUpSheet).to receive(:signup_team).with(any_args).and_return(nil)
            post :signup_as_instructor_action, params
            expect(flash.now[:error]).to eq("The student has already signed up for a topic!")
            expect(response).to redirect_to controller: 'assignments', action: 'edit', id: params[:assignment_id]
          end
        end
      end

      context 'when an assignment_participant cannot be found' do
        it 'shows a flash error message and redirects to assignment#edit page' do
          allow(User).to receive(:find_by).with(any_args).and_return(student)
          allow(AssignmentParticipant).to receive(:exists?).with(any_args).and_return(false)
          post :signup_as_instructor_action, params
          expect(flash.now[:error]).to eq("The student is not registered for the assignment!")
          expect(response).to redirect_to controller: 'assignments', action: 'edit', id: params[:assignment_id]
        end
      end
    end
  end

  describe '#delete_signup' do
    let(:params) { {id: 1, topic_id: 1} }
    context 'when either submitted files or hyperlinks of current team are not empty' do
      it 'shows a flash error message and redirects to sign_up_sheet#list page' do
        allow(team).to receive(:submitted_files).and_return([])
	allow(team).to receive(:hyperlinks ).and_return(['test'])
         delete :delete_signup, params
         expect(flash.now[:error]).to eq("You have already submitted your work, so you are not allowed to drop your topic.")
         expect(response).to redirect_to(action: 'list', id: params[:id])
        allow(team).to receive(:submitted_files).and_return(['test'])
	allow(team).to receive(:hyperlinks ).and_return([])
         delete :delete_signup, params
         expect(flash.now[:error]).to eq("You have already submitted your work, so you are not allowed to drop your topic.")
         expect(response).to redirect_to(action: 'list', id: params[:id])
      end
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is not nil and its due date has already passed' do
      it 'shows a flash error message and redirects to sign_up_sheet#list page' do
        allow(team).to receive(:submitted_files).and_return([])
	allow(team).to receive(:hyperlinks ).and_return([])
        allow(assignment).to receive_message_chain(:due_dates, :find_by_deadline_type_id).with(no_args).with(6).and_return(due_date)
        allow(due_date).to receive(:due_at).and_return(Time.now - 1.second)
        delete :delete_signup, params
        expect(flash.now[:error]).to eq("You cannot drop your topic after the drop topic deadline!")
        expect(response).to redirect_to(action: 'list', id: params[:id])
      end
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is nil' do
      let(:session) { {user: student} }
      it 'shows a flash success message and redirects to sign_up_sheet#list page' do
        allow(team).to receive(:submitted_files).and_return([])
	allow(team).to receive(:hyperlinks ).and_return([])
        allow(assignment).to receive_message_chain(:due_dates, :find_by_deadline_type_id).with(no_args).with(6).and_return nil
        allow(SignedUpTeam).to receive(:reassign_topic).with(any_args)
        allow(SignedUpTeam).to receive(:find_team_users).with(participant.assignment.id, session[:user].id).and_return([signed_up_team2])
        allow(signed_up_team2).to receive(:t_id).and_return(2)
        delete :delete_signup, params, session
        expect(flash.now[:success]).to eq("You have successfully dropped your topic!")
        expect(response).to redirect_to(action: 'list', id: params[:id])
      end
    end
  end

  describe '#delete_signup_as_instructor' do
    let(:params) { {id: 1, topic_id: 1} }
    context 'when either submitted files or hyperlinks of current team are not empty' do
      it 'shows a flash error message and redirects to assignment#edit page' do
          allow(team).to receive(:submitted_files).and_return([])
	  allow(team).to receive(:hyperlinks ).and_return(['test'])
          delete :delete_signup_as_instructor, params
          expect(flash.now[:error]).to eq("The student has already submitted their work, so you are not allowed to remove them.")
          expect(response).to redirect_to controller: 'assignments', action: 'edit', id: assignment.id
          allow(team).to receive(:submitted_files).and_return([])
	  allow(team).to receive(:hyperlinks ).and_return(['test'])
          delete :delete_signup_as_instructor, params
          expect(flash.now[:error]).to eq("The student has already submitted their work, so you are not allowed to remove them.")
          expect(response).to redirect_to controller: 'assignments', action: 'edit', id: assignment.id
      end
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is not nil and its due date has already passed' do
      it 'shows a flash error message and redirects to assignment#edit page' do
        allow(team).to receive(:submitted_files).and_return([])
	allow(team).to receive(:hyperlinks ).and_return([])
        allow(assignment).to receive_message_chain(:due_dates, :find_by_deadline_type_id).with(no_args).with(6).and_return(due_date)
        allow(due_date).to receive(:due_at).and_return(Time.now - 1.second)
        delete :delete_signup_as_instructor, params
        expect(flash.now[:error]).to eq("You cannot drop a student after the drop topic deadline!")
        expect(response).to redirect_to controller: 'assignments', action: 'edit', id: assignment.id
      end
    end

    context 'when both submitted files and hyperlinks of current team are empty and drop topic deadline is nil' do
      let(:session) { {user: instructor} }
      it 'shows a flash success message and redirects to assignment#edit page' do
        allow(team).to receive(:submitted_files).and_return([])
	allow(team).to receive(:hyperlinks ).and_return([])
        allow(assignment).to receive_message_chain(:due_dates, :find_by_deadline_type_id).with(no_args).with(6).and_return nil
        allow(SignedUpTeam).to receive(:reassign_topic).with(any_args)
        allow(SignedUpTeam).to receive(:find_team_users).with(participant.assignment.id, session[:user].id).and_return([signed_up_team2])
        allow(signed_up_team2).to receive(:t_id).and_return(2)
        delete :delete_signup_as_instructor, params, session
        expect(flash.now[:success]).to eq("You have successfully dropped the student from the topic!")
        expect(response).to redirect_to controller: 'assignments', action: 'edit', id: assignment.id
      end
    end
  end

  describe '#set_priority' do
    it 'sets priority of bidding topic and redirects to sign_up_sheet#list page'
  end

  describe '#save_topic_deadlines' do
    context 'when topic_due_date cannot be found' do
      it 'creates a new topic_due_date record and redirects to assignment#edit page'
    end

    context 'when topic_due_date can be found' do
      it 'updates the existing topic_due_date record and redirects to assignment#edit page'
    end
  end

  describe '#show_team' do
    it 'renders show_team page'
  end

  describe '#switch_original_topic_to_approved_suggested_topic' do
    it 'redirects to sign_up_sheet#list page'
  end
end
